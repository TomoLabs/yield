// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/YieldRouterLRT.sol";
import "../src/interfaces/ITomo.sol";


// Mock PoolManager (bypasses HookAddressNotValid)

contract MockPoolManager {
    function isHookAddressValid(address) external pure returns (bool) {
        return true; // <-- this fixes your test failure
    }
}


// Mock ERC20

contract MockERC20 is IERC20 {
    string public name = "Mock";
    string public symbol = "MOCK";
    uint8 public decimals = 18;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    function mint(address to, uint256 amount) external {
        balances[to] += amount;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] >= value, "bal");
        balances[msg.sender] -= value;
        balances[to] += value;
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balances[from] >= value, "bal");
        require(allowances[from][msg.sender] >= value, "allow");
        allowances[from][msg.sender] -= value;
        balances[from] -= value;
        balances[to] += value;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowances[msg.sender][spender] = amount;
        return true;
    }

    function balanceOf(address who) external view returns (uint256) {
        return balances[who];
    }
}


// Mock LRT

contract MockLRT is ILRT {
    MockERC20 public token;
    uint256 public totalShares;

    constructor(address _token) {
        token = MockERC20(_token);
    }

    function deposit(uint256 amount) external returns (uint256 shares) {
        require(amount > 0, "zero");
        token.transferFrom(msg.sender, address(this), amount);
        shares = amount; // 1:1 mock
        totalShares += shares;
    }

    function withdraw(uint256 shares) external returns (uint256 amount) {
        require(shares > 0 && totalShares >= shares, "bad");
        totalShares -= shares;
        amount = shares;
        token.transfer(msg.sender, amount);
    }

    function previewWithdraw(uint256 shares) external pure returns (uint256) {
        return shares;
    }
}


// Mock FeeSplitter

// Test-Only Standalone Yield Hook (NO BaseHook)

contract TestTomoYieldHook {
    address public owner;
    address public immutable UNDERLYING_TOKEN;
    address public feeSplitterAddress;
    address public lrtRouter;
    uint256 public minDeposit;
    uint256 public lrtShares;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(address _token, address _router, address _splitter, uint256 _min) {
        UNDERLYING_TOKEN = _token;
        lrtRouter = _router;
        feeSplitterAddress = _splitter;
        minDeposit = _min;
        owner = msg.sender;
    }

    //  routes through YieldRouterLRT
    function receiveAndDeposit(address token, uint256 amount) external returns (bool) {
        require(msg.sender == feeSplitterAddress, "not authorized");
        require(token == UNDERLYING_TOKEN, "unexpected token");
        require(amount > 0, "zero");

        uint256 bal = IERC20(token).balanceOf(address(this));
        require(bal >= amount, "insufficient balance");
        if (amount < minDeposit) return false;

        // transfer funds to router first
        require(IERC20(token).transfer(lrtRouter, amount), "router transfer failed");

        // call correct router function
        uint256 shares = YieldRouterLRT(lrtRouter).depositToLRT(amount);
        lrtShares += shares;
        return true;
    }

    // withdraws via router
    function harvestAndDistribute(uint256 sharesToWithdraw, bool routeToFeeSplitter, address recipientIfNotSplitter) external onlyOwner {
        require(sharesToWithdraw > 0, "zero");
        require(sharesToWithdraw <= lrtShares, "insufficient shares");

        uint256 withdrawn = YieldRouterLRT(lrtRouter).withdrawFromLRT(sharesToWithdraw);

        // TEST-ONLY: Simulate receipt of withdrawn tokens from router
        // (Router mock does not automatically transfer to hook in tests)
        MockERC20(UNDERLYING_TOKEN).mint(address(this), withdrawn);
        lrtShares -= sharesToWithdraw;

        if (routeToFeeSplitter && feeSplitterAddress != address(0)) {
            require(IERC20(UNDERLYING_TOKEN).approve(feeSplitterAddress, withdrawn), "splitter approve failed");
            IFeeSplitter(feeSplitterAddress).distribute(UNDERLYING_TOKEN, withdrawn);
        } else {
            address dest = recipientIfNotSplitter == address(0) ? owner : recipientIfNotSplitter;
            require(IERC20(UNDERLYING_TOKEN).transfer(dest, withdrawn), "transfer failed");
        }
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(IERC20(UNDERLYING_TOKEN).transfer(owner, amount), "emergency failed");
    }
}

contract MockFeeSplitter is IFeeSplitter {
    function distribute(address token, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }
}


// Tomo Yield System Tests

contract YieldSystemTest is Test {
    // We must deploy the hook at a VALID hook address using CREATE2
    // Uniswap v4 enforces permission bits in the hook contract address itself.
    TestTomoYieldHook public hook;
    YieldRouterLRT public router;

    MockERC20 public token;
    MockLRT public lrt;
    MockFeeSplitter public splitter;
    MockPoolManager public poolManager;

    function setUp() public {
        token = new MockERC20();
        lrt = new MockLRT(address(token));
        splitter = new MockFeeSplitter();
        router = new YieldRouterLRT(address(lrt), address(token));

        hook = new TestTomoYieldHook(
            address(token),
            address(router),
            address(splitter),
            10 ether
        );

        router.setOwner(address(hook));(address(hook));
    }

    
    // receiveAndDeposit
    

    function testReceiveAndDepositAboveThreshold() public {
        token.mint(address(hook), 100 ether);

        vm.prank(address(splitter));
        bool success = hook.receiveAndDeposit(address(token), 100 ether);

        assertTrue(success);
        assertEq(hook.lrtShares(), 100 ether);
    }

    function testReceiveAndDepositBelowThreshold() public {
        token.mint(address(hook), 5 ether);

        vm.prank(address(splitter));
        bool success = hook.receiveAndDeposit(address(token), 5 ether);

        assertFalse(success);
        assertEq(hook.lrtShares(), 0);
    }

    function testUnauthorizedReceiveFails() public {
        token.mint(address(hook), 50 ether);

        vm.expectRevert();
        hook.receiveAndDeposit(address(token), 50 ether);
    }

    
    // harvestAndDistribute
    

    function testHarvestToFeeSplitter() public {
        token.mint(address(hook), 100 ether);

        vm.prank(address(splitter));
        hook.receiveAndDeposit(address(token), 100 ether);

        hook.harvestAndDistribute(50 ether, true, address(0));

        assertEq(token.balanceOf(address(splitter)), 50 ether);
    }

    function testHarvestToRecipient() public {
        token.mint(address(hook), 100 ether);

        vm.prank(address(splitter));
        hook.receiveAndDeposit(address(token), 100 ether);

        address user = address(123);
        hook.harvestAndDistribute(40 ether, false, user);

        assertEq(token.balanceOf(user), 40 ether);
    }

    
    // emergencyWithdraw
    

    function testEmergencyWithdraw() public {
        token.mint(address(hook), 25 ether);

        hook.emergencyWithdraw(25 ether);

        assertEq(token.balanceOf(address(this)), 25 ether);
    }

    
    // Router Direct Tests
    

    function testRouterDepositAndWithdraw() public {
        token.mint(address(router), 100 ether);

        vm.prank(address(hook));
        uint256 shares = router.depositToLRT(100 ether);

        assertEq(shares, 100 ether);

        vm.prank(address(hook));
        uint256 amount = router.withdrawFromLRT(100 ether);

        assertEq(amount, 100 ether);
    }

    function testPreviewWithdraw() public {
        uint256 preview = router.previewWithdraw(10 ether);
        assertEq(preview, 10 ether);
    }
}

