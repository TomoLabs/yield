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
