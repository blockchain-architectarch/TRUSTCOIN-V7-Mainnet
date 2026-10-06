# TRUSTCOIN — Holder Record Guide (V7 Mainnet)

## Why This Matters
TRUSTCOIN V7 runs on a 50-cycle emission schedule, with cycle 50 completing
no later than **December 2030**. Once cycle 50 completes, a snapshot of all
holders is taken, and the Cumulative Immutable Loyalty Vault — once
deployed — will distribute rewards based on that snapshot.

Your eligibility is determined on-chain, but you must maintain your own
independent record as a personal backup. We maintain our registry. You
must maintain yours.

## What to Record Immediately
Record this for **every purchase** — each top-up is a separate lot with its own G.

- **TX Hash:** Your transaction hash (from Etherscan/wallet)
- **Date & Time:** Transaction timestamp in UTC
- **Cycle:** The number of `monthlyRelease()` calls executed before your purchase (cycle 1 began September 20, 2026). Check the latest `MonthlyReleaseExecuted` event on the token's Etherscan page.
- **G-Coefficient:** The G of that cycle (see [TRUSTCOIN_COEFFICIENT_G.md](TRUSTCOIN_COEFFICIENT_G.md))
- **Wallet Address:** The exact address used for the purchase
- **Amount:** TRUST tokens bought in this purchase

Never send TRUST out of this wallet — one outbound transfer removes it from the programme forever. Full rules: [TRUSTCOIN_LOYALTY_REWARDS.md](TRUSTCOIN_LOYALTY_REWARDS.md).

## How to Store It
- **Write it on paper** and keep it in a secure location
- **Save a screenshot** of the Etherscan transaction page
- **Do not rely on memory** — this runs for years. Paper is more reliable
  than disk storage

## Key Data & Core Parameters
- **Contract Address (V7 — Ethereum Mainnet):** `0xfDe6a8FA6658e59EfD07dEBe3d0bd073F820D293`
- **Contract Deployed:** September 20, 2026
- **First monthlyRelease():** September 20, 2026 (cycle 1)
- **Loyalty Vault Snapshot:** at cycle 50 completion, no later than December 2030
- **Loyalty Vault Opens:** planned ~2030, once deployed. **Not deployed
  yet — no address exists. Anyone who gives you an address is a scammer.**

## A Note on Ownership
Until `renounceOwnership()` is called on these contracts, an owner key
still exists and can perform administrative actions (setting bridges,
oracle, exempt addresses). There is no `pause()` function in any of the
three contracts. This guide will be updated if and when ownership is
renounced.

```
[Action Flow]
Buy TRUST → Open Etherscan → Record Data (Hash/Date/Cycle/G-Coeff/Wallet/Amount)
→ Store (Paper + Screenshot) → Hold through cycle 50 → Claim once the
Loyalty Vault deploys → Claim or check in at least every 3 years.
```
