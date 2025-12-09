                                        TomoYieldHook

TomoYieldHook converts Uniswap v4 swap fees into auto-compounding restaking yield by routing earned fees directly into Liquid Restaking Token (LRT) protocols via a programmable Uniswap v4 Hook and a modular YieldRouterLRT adapter. It functions as a fully autonomous, non-custodial yield engine that turns DEX trading volume into passive EigenLayer restaking rewards.

   OVERVIEW

TomoYieldHook is a mainnet-live Uniswap v4 Hook that captures swap fees at the protocol level and reinvests them into EigenLayer LRTs to generate autonomous, compounding yield. This transforms Uniswap liquidity and trading activity into a programmable yield stream that DAOs, LPs, FeeSplitters, and creator economies can route, split, or automate.

End-to-end yield automation — including fee capture, LRT deposit, share accounting, yield harvesting, and distribution — is implemented entirely on-chain and validated across local, testnet, and Ethereum mainnet environments.

      ✨ Live on Ethereum • Powered by Uniswap v4 Hooks • EigenLayer Restaking Integrated
      

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
   

FEATURES:


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
  


USAGE GUIDE:

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
