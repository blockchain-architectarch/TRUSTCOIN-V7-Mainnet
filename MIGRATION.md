# Migration: V6.2 → V7 Mainnet

**September 20, 2026** — TrustcoinV6.2 was retired. `renounceOwnership()`
was called on it after a permanent per-wallet limit (4,000,000 TRUST) made
it impossible for the liquidity pool to keep receiving sales. Once the
owner is renounced, that limit can no longer be changed — so the fix had
to ship as a new contract, not a patch.

**What changed in V7:**
- Per-wallet cap now expires on a fixed calendar date (June 1, 2027),
  not a permanent ceiling
- The exempt-address list is now editable (`setExempt`), so a future
  pool or auction contract can be added without another migration
- Emission shortened from 72 to 50 monthly cycles, 4,000,000 TRUST
  per cycle instead of 2,777,778
- TaxBridge split changed to 80% holders / 10% guards / 10% charity
- `oracleAdmin` and `exemptAdmin` can now hand off their own role
  without an owner, so they still work after `renounceOwnership()`

**What stayed the same:** the token symbol, the total supply
(200,000,000), the 50% burn on every release, the 0.5% base tax, and
the Panic Tax mechanism.

The old repository — [TRUSTCOIN (V6.2)](https://github.com/blockchain-architectarch/TRUSTCOIN)
— is kept as history and archived. This repository is the live version.
