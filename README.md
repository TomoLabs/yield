 TomoYieldHook — Yield-Generating Uniswap v4 Hook

TomoYieldHook transforms Uniswap v4 swap fees into real, auto-compounding restaking yield by routing accumulated fees into an external Liquid Restaking Token (LRT) protocol (e.g., ezETH).
It upgrades AMMs from passive liquidity to productive, yield-bearing liquidity rails.

This repository contains:

TomoYieldHook.sol — Uniswap v4 Hook for fee-to-yield automation

YieldRouterLRT.sol — Router that converts fee tokens → LRT shares

Deployment scripts (DeployTomoYield.s.sol)

Pool creation scripts (CreatePool.s.sol)

 Core Idea

Uniswap v4 generates fees on every swap.
TomoYieldHook captures those fees, batches them, and deposits them into an LRT (restaking) protocol, converting idle swap fees into productive yield.

Swap → Fees → Hook → LRT → Auto-Compounding Yield

This creates a Creator-Aligned Liquidity Layer, enabling:

Revenue sharing for creators/DAOs

Protocol-native yield on trading activity

Restaking-powered AMM incentives

Smart fee routing at the protocol layer

 How It Works (Short Version)

Swaps occur in a Uni v4 pool using this Hook
→ trading fees accumulate.

FeeSplitter (or bot) transfers fee tokens to the Hook
→ Hook calls receiveAndDeposit().

Hook batches deposits
→ only deposits when amount >= minDeposit.

Hook deposits WETH into the LRT protocol
→ through YieldRouterLRT.

Router mints LRT shares (e.g., ezETH)
→ these automatically grow via restaking rewards.

Owner/keeper harvests yield
→ Hook withdraws rewards and sends them to

a FeeSplitter

a DAO

LPs

the creator

 Architecture
Uniswap V4 Pool
       │
       ▼
+-------------------+
|   TomoYieldHook   |  ← afterSwap() callback
+-------------------+
       │
       ▼
  receiveAndDeposit()
       │
       ▼
+-------------------+
|  YieldRouterLRT   |
+-------------------+
       │
       ▼
   LRT Protocol
 (ezETH / rsETH)

 Contracts
1️ TomoYieldHook.sol

Listens to afterSwap()

Receives fee tokens from FeeSplitter

Batches deposits using minDeposit

Deposits to LRT using YieldRouterLRT

Manages & harvests accumulated LRT shares

Key functions:

receiveAndDeposit(token, amount)
harvestAndDistribute(shares, routeToFeeSplitter, recipient)

2️ YieldRouterLRT.sol

A minimal adapter for LRT staking:

depositToLRT(amount) → returns LRT shares

withdrawFromLRT(shares) → returns underlying token

Supports preview withdrawing

 Deployment (Mainnet)




Deploy:

forge script script/DeployTomoYield.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --slow


You will get two contracts:

YieldRouterLRT deployed at: 0x...
TomoYieldHook deployed at: 0x...

 Creating a Uniswap V4 Pool with This Hook

Run:

forge script script/CreatePool.s.sol \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast --slow


This creates a new pool that activates your hook.

NOTE: Pool creation must happen on testnet or local v4 instance,
because mainnet v4 pools are not yet live.

 How Yield Is Generated

TomoYieldHook does NOT generate yield by itself.
It routes tokens into a restaking protocol which generates the yield.

Yield comes from:

LRT staking rewards

EigenLayer restaking

AVS revenue

Your hook is the automation engine connecting swaps → yield.

 Testing

Run Foundry tests:

forge test -vvv


You can simulate:

swaps

fee accumulation

batched deposits

harvesting and distribution

 Requirements

Foundry

Uniswap v4-periphery (compatible version)

Uniswap v4-core (hook-capable)

LRT adapter (e.g., Renzo, Ether.fi, Puffer, etc.)

 Status

✔ Hook deployed successfully

✔ Router deployed successfully

✔ Pool creation script works

✔ Swap → fee → yield flow fully functional

⚠ Only testnet/local pools for now (until V4 mainnet launch)

License

MIT License.

Contributing

We welcome:

new fee routing strategies

new yield strategies (Pendle, EigenLayer AVSs, LRT baskets)

x-chain payout experiments

analytics dashboards

optimizations to reduce gas

 Author

TomoLabs
Protocol-Level Liquidity Infrastructure
Creator-Aligned Fee Systems • Restaking-Powered Liquidity • Uniswap v4 Innovation
