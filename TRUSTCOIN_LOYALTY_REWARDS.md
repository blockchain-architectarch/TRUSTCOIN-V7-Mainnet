# TRUSTCOIN V7 — Loyalty Rewards

**We don't promise an amount. We guarantee a share — by code.**

This document explains how TRUSTCOIN loyalty rewards work: who qualifies, how your share is calculated, where the rewards come from, and how you collect them. Everything described here is enforced by smart contracts or computed from public on-chain data that anyone can verify.

---

## 1. In one minute

- Hold **1,000 TRUST or more** in your own wallet.
- **Never send TRUST out** of that wallet. One outbound transfer, of any amount, to anyone, removes the wallet from the programme permanently.
- Every coin you buy carries the **G-weight of the month you bought it** (10.0 in month 1 down to 0.2 in month 50).
- At month 50 your **share is fixed forever**: your points ÷ the points of all qualified holders.
- From then on, you receive that share of **everything** TaxBridge sends to the Loyalty Vault, now and in the future.
- Rewards are paid **only in TRUST**. You claim them yourself. What you do with them afterwards is up to you.

---

## 2. Where the rewards come from

Every taxed TRUST transfer pays **0.5%**: 0.25% to the Fund and **0.25% to TaxBridge**
([`TaxBridgeV7Mainnet`](https://etherscan.io/address/0x63BA7E1300e68dBD64f61673F19a1670416143d3)).

TaxBridge accumulates TRUST and is **locked until all 50 monthly releases are done**. After that, anyone can call `distribute()` once every 90 days, and the balance is split by code:

| Share | Goes to |
|---|---|
| **80%** | Holders — the Loyalty Vault |
| 10% | Guards |
| 10% | Charity |

The holders' destination is set once. Any change to it has a **365-day public timelock** written into the contract.

The size of the reward pool depends on one thing only: **how much TRUST moves through the market.** We do not know that number, and nobody else does. It can be small or very large.

---

## 3. Who qualifies

| Rule | Detail |
|---|---|
| **Entry** | A wallet enters the first time its balance reaches **≥ 1,000 TRUST**. 999.99 is not enough. |
| **No-Sale rule (the Guillotine)** | After entry, **any** outbound transfer — a sale, a transfer to your other wallet, a deposit anywhere, even 1 wei — disqualifies the wallet **forever**. There is no re-entry. |
| **Before entry** | Movements before the wallet first reaches 1,000 TRUST do not count against you. |
| **Buying more** | Incoming TRUST never hurts you. Buy as often as you like. |
| **Upper limit** | None. Until **1 June 2027** the token itself caps any wallet at 10,000 TRUST; after that date there is no cap. |
| **Self-custody only** | Only coins in a wallet you control count. Coins on a centralised exchange are the exchange's wallet, not yours. |
| **One wallet = one account** | Points cannot be merged or moved. Moving coins to another wallet is an outbound transfer and disqualifies the sender. |

---

## 4. How your share is calculated

### Month = release number
"Month M" is **not** a calendar month. It is the number of `monthlyRelease()` calls executed on the token before your purchase (event `MonthlyReleaseExecuted`). A purchase after release #3 and before release #4 is month 3. Anyone can check this on Etherscan.

### G-weight
`G(M) = 10.0 − 0.2 × (M − 1)` — month 1 = **10.0**, month 50 = **0.2**, exact step 0.20, no rounding.
Full table: [`TRUSTCOIN_COEFFICIENT_G.md`](TRUSTCOIN_COEFFICIENT_G.md).

### Lots and points
- When your wallet enters, its whole balance becomes **lot 1** with the G of that month.
- Each later purchase is a **new lot** with the G of its own month.
- TRUST received as rewards from the system (pools, TaxBridge, Vault) adds to your balance but earns **no** points.

**Your points = Σ (coins in each lot × G of that lot).**

### Example
| Purchase | Month | G | Coins | Points |
|---|---|---|---|---|
| At launch | 1 | 10.0 | 10,000 | 100,000 |
| Top-up | 9 | 8.4 | 5,000 | 42,000 |
| Top-up | 21 | 6.0 | 10,000 | 60,000 |
| Top-up | 33 | 3.6 | 5,000 | 18,000 |
| Top-up | 45 | 1.2 | 10,000 | 12,000 |
| **Total** | | | **40,000** | **232,000** |

### Your share
At month 50:

**Your share = your points ÷ total points of all qualified holders.**

It is fixed once, permanently. Every future distribution to the Loyalty Vault is divided by these shares.

### Calculate it yourself
For any reward amount you want to assume:

**Reward per point = TRUST arriving in the Vault ÷ total points**
**Your reward = your points × reward per point**

*Illustration only:* if total points were 30,000,000 and 3,000,000 TRUST arrived in the Vault, one point would earn 0.1 TRUST. The wallet above would receive 23,200 TRUST from that distribution. These numbers are made up to show the arithmetic. They are not a forecast.

---

## 5. How you collect

- Rewards are held in the **CumulativeImmutableLoyaltyVault**, deployed near month 50. Its address will be published here.
- You **claim** your rewards yourself. Nothing is pushed to your wallet automatically.
- Claiming requires a one-time **KYC** check for that Vault. This is what makes one person = one claim.
- Rewards are paid **only in TRUST**. Swap, hold or use them however you like — after you claim, they are yours.
- **Stay active.** If a wallet does not claim (or check in with a zero-amount claim) for **3 years**, its unclaimed rewards are forfeited to the charity hub.

---

## 6. What is guaranteed — and what is not

| Guaranteed by code | Not guaranteed by anyone |
|---|---|
| The entry threshold and the No-Sale rule | The price of TRUST |
| The G-table and how points are calculated | Trading volume |
| Your share, fixed at month 50 | The size of any reward |
| 80% of TaxBridge going to holders, every 90 days, callable by anyone | When — or whether — rewards become significant |
| TRUST as the only reward currency | |

TRUST starts trading around a **$0.05 reference floor**. We publish no price target. If the market grows, your share grows with it. If it doesn't, it doesn't. You may do very well — or not — and nobody can tell you when.

**This is not investment advice and not a promise of profit.** Only commit what you can afford to hold for years without needing it back.

---

## 7. Verify everything

- Token: [`0xfDe6a8FA6658e59EfD07dEBe3d0bd073F820D293`](https://etherscan.io/address/0xfDe6a8FA6658e59EfD07dEBe3d0bd073F820D293)
- TaxBridge: [`0x63BA7E1300e68dBD64f61673F19a1670416143d3`](https://etherscan.io/address/0x63BA7E1300e68dBD64f61673F19a1670416143d3)
- All contracts are source-verified on Etherscan and published in this repository.
- Eligibility and points are computed only from public `Transfer` and `MonthlyReleaseExecuted` events. The reference script that produces the final snapshot will be published, so anyone can rerun it and get the same result, byte for byte.
- Keep your own records: transaction hash, date, month number and amount for every purchase. See the holder record-keeping guide in this repository.
