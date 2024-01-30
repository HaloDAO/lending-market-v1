## Qs for Chris

- Which tokens do we want to allow for:
  - deposit
  - borrow
- Do we still do incentives for the users of the lending market?
  - If yes, what reward token(s) do we want to use as incentives?
- What network(s) we want to deploy first?
- How will we utilize the lending market product now? (context: in the past the LendingM was used in combination with XaveStrats)
- Will the utility/function of the “XaveLendingToken” be exactly the same with the Aave V2 reward token?
- Will the “XaveLendingToken” be open for market trading?
- Do we want to implement the stkAAVE module/ insurance module?

---

ETHBorrowable = 107.89206652 + 0.86124305
totalETHBorrowable = 108.75330957
ETH Price = 1448.49
LP Price in ETH = 0.00070764
LP Price in USD = 1448.49 \* 0.00070764 = 1.02500946
USDC Price = 100002417

USDC Borrowable = 156,276.802229
USDC Deposited = 167,953.74573

total USD Borrowable = 108.75330957 \* 1448.49 = 157528.08137905

156,276.802229 / 167,953.74573
156276.802229 / 167953.74573 = 0.93047524

157528.08137905 / 167953.74573 = 0.93792538

aToken 82658718363
USDC 82658718363

    /**

rvs 0 0x6B175474E89094C44Da98b954EedeAC495271d0F
rvs 1 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
rvs 2 0xdAC17F958D2ee523a2206206994597C13D831ec7
rvs 3 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599
rvs 4 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
rvs 5 0x70e8dE73cE538DA2bEEd35d14187F6959a8ecA96
rvs 6 0x64DCbDeb83e39f152B7Faf83E5E5673faCA0D42A

\*/

    // address[] memory rvs = LP.getReservesList();
    // console.log('rvs 0', rvs[0]); // DAI
    // console.log('rvs 1', rvs[1]); // USDC
    // console.log('rvs 2', rvs[2]); // USDT
    // console.log('rvs 3', rvs[3]); // WBTC
    // console.log('rvs 4', rvs[4]); // WETH
    // console.log('rvs 5', rvs[5]); // XSGD
    // console.log('rvs 6', rvs[6]); // XSGD HLP

    // console.log('ETH/USD price', uint256(price));

### Test for HLP Oracle contract

- get price for HLP Token (1)
- manipulate ratio of FXPool
- get price for HLP Token (2)
- (1) should === (2)
- if not then ...
-     Oracle Network

## !!! HLP Oracle FXPool ratio manipulation scenario (assumptions) !!!

- Start state FXPool 40% XSGD / 60% USDC
- Bob deposits XSGD / USDC LP tokens as collateral into LendingPool
- Bob draws USDC loan against his LP tokens
- Lending Pool marks his LTV at 60% relative to his collateral
- 1 TX
-     Swap: Sells XSGD into FXPool (XSGD/USDC) takes it out of BETA
-     FXPool state: 80% XSGD / 20% USDC
-     Question
-     Has price changed?
-     Calls `liquidationCall` on the lendingPool
-     Lending Pool checks price of LP token

[SWAP 1] lpEthPrice2 451896018515278
[SWAP 2] lpEthPrice2 451891824293920
[SWAP 3] lpEthPrice2 451888783425125
[SWAP 4] lpEthPrice2 451884551478237
[SWAP 5] lpEthPrice2 451881480859627
[SWAP 6] lpEthPrice2 451877211893786
[SWAP 7] lpEthPrice2 451874112095126
[SWAP 8] lpEthPrice2 451869806798860
[SWAP 9] lpEthPrice2 451866678373583
[SWAP 10] lpEthPrice2 451862337407098
[SWAP 11] lpEthPrice2 451859180898801
[SWAP 12] lpEthPrice2 451854804914416

--- WITH MINT FEES ---
[SWAP 1] lpEthPrice2 451967559880610
[SWAP 2] lpEthPrice2 451922424678916
[SWAP 3] lpEthPrice2 451898336528399
[SWAP 4] lpEthPrice2 451850213913532
[SWAP 5] lpEthPrice2 451822231674150
[SWAP 6] lpEthPrice2 451771567479617
[SWAP 7] lpEthPrice2 451740426050435
[SWAP 8] lpEthPrice2 451687574648662
[SWAP 9] lpEthPrice2 451653820432194
[SWAP 10] lpEthPrice2 45159906815667
[SWAP 11] lpEthPrice2 45156311844918
[SWAP 12] lpEthPrice2 45101353137727

S2 - S3: 451922424678916 - 451898336528399 = 24088150517
S3 - S4: 451898336528399 - 451850213913532 = 48122614867

--- WITH Oracle Update Unclaimed Fees Subtraction ---

[SWAP 1] lpEthPrice2 451860496073837
[SWAP 2] lpEthPrice2 451818837695288
[SWAP 3] lpEthPrice2 451787779816214
[SWAP 4] lpEthPrice2 451746134843830
[SWAP 5] lpEthPrice2 451715086959581
[SWAP 6] lpEthPrice2 451673455386891
[SWAP 7] lpEthPrice2 451642417490979
[SWAP 8] lpEthPrice2 451600799311517
[SWAP 9] lpEthPrice2 451569771400786
[SWAP 10] lpEthPrice2 451528166608090
[SWAP 11] lpEthPrice2 451497148676060
[SWAP 12] lpEthPrice2 451090806445253

S2 - S3: 451818837695288 - 451787779816214 = 31057879074
S3 - S4: 451787779816214 - 451746134843830 = 41644972384

---

452141146998027 - 452141146996359
452141146998027 - 452141146996359

452141146996359 - 452141146995692

---

---

---

---

--- WITHOUT MINT FEES ---
[SWAP 1] lpEthPrice2 451580193343823
[SWAP 2] lpEthPrice2 451496987584777
[SWAP 3] lpEthPrice2 451434964549626
[SWAP 4] lpEthPrice2 451351812295214
[SWAP 5] lpEthPrice2 451289829137777
[SWAP 6] lpEthPrice2 451206730336407
[SWAP 7] lpEthPrice2 451144787016577
[SWAP 8] lpEthPrice2 451061741616724 
[SWAP 9] lpEthPrice2 450999838097767
[SWAP 10] lpEthPrice2 450916846047970
[SWAP 11] lpEthPrice2 450854982289879
[SWAP 12] lpEthPrice2 450045334556097

--- MINT FEES AFTER ALL SWAPS ---

[SWAP 1] lpEthPrice2 451580193343823
[SWAP 2] lpEthPrice2 451496987584777
[SWAP 3] lpEthPrice2 451434964549626
[SWAP 4] lpEthPrice2 451351812295214
[SWAP 5] lpEthPrice2 451289829137777
[SWAP 6] lpEthPrice2 451206730336407
[SWAP 7] lpEthPrice2 451144787016577
[SWAP 8] lpEthPrice2 451061741616724
[SWAP 9] lpEthPrice2 450999838097767
[SWAP 10] lpEthPrice2 450916846047970
[SWAP 11] lpEthPrice2 450854982289879
[SWAP 12] lpEthPrice2 450045334556097


--- Total Supply plus unclaimed fees in numeraire ---


### Inflate the totalSupply on the same block attack vector
- If attacker was to inflate `totalUnclaimedFeesInNumeraire` by doing 1000x swaps then calling joinPool or exitPool to invoke _mintProtocolFees()
- What will be the effect of the inflated totalSupply to the latestAnswer()?


### Profit driven attack

- how much FXPool swap fees do I pay for % price change vs liquidation bonuses
- can I make a net profit from: liquidationBonuses - FXPoolSwapFees

### Griefing driven attack

- pay FXPool swap fees to change LP token price -> liquididate position(s)
- they're making a loss

451750444428150 - 439796093459118

lpEthPrice0 451750444428150
lpEthPrice1 451645026530616

LiquidityNumeraire diff = 126612650000000000000
fees diff = 63306324419696319301

Within the BETA region
70% USDC 30% XSGD

Swap n XSGD for USDC
FX price

60% USDC 40% XSGD (FXpool)
58% USDC 42% XSGD (UniV)

## Liquidation test

- `Liquidate.Integrate.t.sol`
- update to use Polygon (same like HLPPriceFeedOracle.t.sol)
- ensure add LP Token instead of HLP
- \_deployReserve
- \_deployAndSetLPOracle
- luquidate
- profit!!!

```
551709 - 542450 = 9259

9259 / 542450 = 0.01706885
```
