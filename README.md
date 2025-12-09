   # TomoYieldHook



A production-grade Uniswap v4 Hook that converts live swap fees into EigenLayer-secured, auto-compounding restaking yield using Liquid Restaking Tokens (LRTs).

   ✅ Live on Ethereum Mainnet  
   ✅ Contracts Verified on Etherscan  
   ✅ End-to-End Yield Flow Operational  
   ✅ Production-Grade Hook Architecture  
 

TomoYieldHook routes Uniswap v4 trading fees directly into EigenLayer LRTs via a programmable Hook and modular YieldRouterLRT adapter. It functions as a fully autonomous, non-custodial yield engine that turns pure DEX trading volume into continuously compounding restaking rewards for DAOs, LPs, creators, and on-chain automation systems.


   ## OVERVIEW

TomoYieldHook is a mainnet-live Uniswap v4 Hook that captures swap fees at the protocol level and reinvests them into EigenLayer LRTs to generate autonomous, compounding yield. This transforms Uniswap liquidity and trading activity into a programmable yield stream that DAOs, LPs, FeeSplitters, and creator economies can route, split, or automate.

End-to-end yield automation — including fee capture, LRT deposit, share accounting, yield harvesting, and distribution — is implemented entirely on-chain and validated across local, testnet, and Ethereum mainnet environments.

      ✨ Live on Ethereum • Powered by Uniswap v4 Hooks • EigenLayer Restaking Integrated

EigenLayer Integration:

   TomoYieldHook is natively integrated with the EigenLayer restaking ecosystem, enabling Uniswap v4 swap fees to be converted into Liquid Restaking Tokens (LRTs) such as      ezETH, rsETH, or METH. This transforms ordinary DEX trading volume into a restaked yield engine that compounds automatically and can be programmatically routed to DAOs,     LPs, creators, protocol treasuries, or Splitwise-style automation modules.

   This integration demonstrates how EigenLayer + Uniswap v4 Hooks unlock a new DeFi design space where liquidity, trading activity, and restaking yield become a unified       stream of programmable value. TomoYieldHook illustrates how restaking can be embedded natively inside AMM flows, creating a fully autonomous “yield layer” on top of         liquidity provisioning — a core theme for the EigenLayer x Uniswap v4 Hook Incubator.

   

Why This Matters for EigenLayer

   1) Converts Uniswap trading volume into EigenLayer-secured yield.

   2) Generates continuous LRT deposits without user interaction.

   3) Demonstrates a novel use case: Restaking as a Hook Primitive.

   4) Proves LRTs can act as programmable, composable yield routers directly inside AMM execution.

   5) Encourages new on-chain applications that monetize trading activity using restaking rewards.

TomoYieldHook can optionally route harvested EigenLayer yield into on-chain automation systems such as Splitwise-style debt settlement.


How the Integration Works

1. Fee Capture (Uniswap v4 → Hook)

    afterSwap() extracts swap fees from the pool manager.
   

2. YieldRouterLRT Conversion

    Fees are passed into the YieldRouterLRT adapter, which:

      1) Approves the LRT contract

      2) Deposits underlying (e.g., WETH → ezETH)

      3) Returns newly minted LRT shares
         

3. Restaking Yield Accrual (EigenLayer)

     These shares continuously earn EigenLayer rewards without further interaction.


4. Automated Yield Distribution

     When harvested:

      1) Yield can be routed to FeeSplitters

      2) Paid out to DAO treasuries

      3) Sent to LPs

      4) Or used to settle debts (e.g., Splitwise Hook integration)
  
        
5. Full Transparency

      All restaking deposits, withdrawals, and share balances are fully on-chain and event-driven.


EigenLayer Restaking Compatibility:

  TomoYieldHook is designed to operate seamlessly with EigenLayer Liquid Restaking Tokens (LRTs) to convert swap fees into compounding yield. Supported capabilities           include:

   1) Automated WETH → LRT conversion

   2) Share-based accounting for restaked positions

   3) Native EigenLayer reward accrual through LRT mechanisms

   4) Programmable yield withdrawals and routing

   5) Plug-and-play support for any adapter-compliant LRT
      

CORE PRINCIPLES: 

 1️. Passive Yield Extraction

   Trading activity in Uniswap v4 automatically generates yield; no user approvals or active management required.

 2️. Composable Hook-Powered Automation

   Yield routing is performed entirely by a v4 hook (afterSwap), enabling seamless programmability inside AMM flow.

 3️. Modular Restaking Architecture

   The YieldRouterLRT adapter abstracts LRT interactions, enabling plug-and-play support for any EigenLayer-compatible LRT.

 4️. Permissioned Yet Non-Custodial

   Only the configured FeeSplitter and owner can trigger yield operations — but funds remain entirely non-custodial, without pooled user deposits.

 5️. Transparent & Verifiable

   All deposits, withdrawals, shares, and yield distributions are emitted on-chain for complete auditability.
   

## FEATURES


1. Hook-Level Fee Capture (Uniswap v4)

   1) Runs in afterSwap

   2) Detects fee deltas for token0 / token1

   3) Aggregates yield internally

   4) Does not modify swap execution path (gas-optimized)
      

2. Automated LRT Deposits

 Using the YieldRouterLRT adapter, TomoYieldHook:

  1) Approves LRT router

  2) Deposits underlying (e.g., WETH → ezETH)

  3) Tracks shares received

  4) Enforces minimum deposit threshold (minDeposit) to prevent dust deposits

     

3. Yield Harvesting & Distribution

   Harvests accumulated LRT yield via:

                 harvestAndDistribute(sharesToWithdraw, routeToFeeSplitter, fallbackRecipient)


   Supports:

     1) FeeSplitter distribution (DAO multisig, LP splitters, creator payouts)

     2) Direct owner payouts

     3) Configurable routing logic
        

4. Full Restaking Compatibility

    Works with any LRT supporting:

               deposit(amount)
   
               withdraw(shares)
   
               previewWithdraw(shares)


    Examples:

      1) ezETH

      2) rsETH

      3) METH

      4) Renzo LRT

      5) Swell LRT
         

5. Role-Safe Security Model

     1) onlyOwner for all sensitive actions

     2) FeeSplitter restricted for inbound yield

     3) No pool funds are ever held in custody

     4) Hook cannot remove LP or trader funds — only fees provided by the pool manager
        

6. Gas-Optimized Runtime

     1) Minimal logic inside afterSwap

     2) Heavy operations offloaded to external functions

     3) Zero unnecessary storage writes during swap phase
  


## USAGE GUIDE

1. Deploy the Yield Router

    Deploy YieldRouterLRT with:

                 LRT address (ezETH)
   
                 Underlying token address (WETH)


    This router handles:

      1) Deposits into LRT

      2) Withdrawals

      3) Share previews
  
         

2. Deploy TomoYieldHook

   Provide:

      1) Uniswap v4 PoolManager

      2) Underlying token (WETH)

      3) LRT router address

      4) FeeSplitter

      5) Minimum deposit threshold
  
         

3. Link FeeSplitter
   
                   setFeeSplitter(address splitter)


     FeeSplitter allows:

      1) Automated sharing schedules

      2) DAO revenue distribution

      3) LP revenue routing
  
         

4. Yield Accumulation

   Swap flow:

                   User Swap → afterSwap() → Fee Accrued → TomoYieldHook Receives Fees


   Fees accumulate inside the hook until minDeposit is reached.

  

5. Deposit to LRT

    Triggered via:

                    receiveAndDeposit(token, amount)


   Called by:

      1) FeeSplitter

      2) Owner

   Router mints LRT shares → Hook stores share count.

   

6. Harvest Yield

   Owner can harvest restaking rewards:

                   harvestAndDistribute(shares, routeToFeeSplitter, recipient)


   Supports:

      1) DAO payouts

      2) Creator income

      3) Auto-compounding cycles



## ARCHITECTURE 


        ┌──────────── Trader Swap ─────────────┐
                            │
                   ┌────────▼────────┐
                   │ Uniswap v4 Pool │
                   └────────┬────────┘
                            │ afterSwap()
                   ┌────────▼────────┐
                   │ TomoYieldHook   │  ◄─ Fee accumulation
                   └────────┬────────┘
                            │
                 ┌──────────▼──────────┐
                 │ YieldRouterLRT      │  ◄─ LRT deposit logic
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │ EigenLayer LRT      │  ◄─ ezETH / rsETH etc.
                 └──────────┬──────────┘
                            │
                 ┌──────────▼──────────┐
                 │ FeeSplitter / DAO   │  ◄─ Automated distribution
                 └─────────────────────┘



## SECURITY MODEL


1) Hook performs no privileged actions during swap execution
2) No external tokens can be drained — only pool-provided fees are used
3) Only owner + FeeSplitter can initiate routing
4) LRT deposits/withdrawals validated with try/catch
5) Emergency withdrawal limited to owner and only for underlying token
6) No reentrancy vectors in core logic
7) No dependence on external off-chain systems
8) Hook address validated via Uniswap v4 Hook permissions system



## References


- [EigenLayer](https://app.eigenlayer.xyz/)
- [Uniswap v4 Hooks](https://docs.uniswap.org/contracts/v4/concepts/hooks)
- [OpenZeppelin](https://www.openzeppelin.com/)


🔗 Mainnet Deployment (Ethereum)

   TomoYieldHook (Uniswap v4 Yield Automation Hook)
   
         0xeda704f59db7818e16f189b6ac97caf3895ca290

   https://etherscan.io/address/0xeda704f59db7818e16f189b6ac97caf3895ca290
   

   YieldRouterLRT (EigenLayer LRT Router)
   
         0x5bcee69b20ea366c2c0166d3efca13121e07c94b

   https://etherscan.io/address/0x5bcee69b20ea366c2c0166d3efca13121e07c94b

