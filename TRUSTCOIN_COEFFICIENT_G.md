# TRUSTCOIN — Coefficient G (V7 Mainnet, 50 months)

Off-chain holder-weight multiplier used when building the Merkle tree for the
Cumulative Immutable Loyalty Vault snapshot at month 50.

Formula: `G(M) = 10.0 - 0.2 × (M - 1)`

Month 1 corresponds to the first monthly release (October 2026); month 50
falls no later than December 2030.

- Month 1 → 10.00 (maximum weight)
- Month 50 → 0.20 (minimum weight)
- Weight ≈ 1.00 at month 46

This table supersedes the old V6.2 table (72 months, step ≈0.1388). Every
value below must be used as-is, with no rounding, when assembling the tree.

| Month | G | Month | G | Month | G |
|:-:|:-:|:-:|:-:|:-:|:-:|
| 1 | 10.00 | 18 | 6.60 | 35 | 3.20 |
| 2 | 9.80 | 19 | 6.40 | 36 | 3.00 |
| 3 | 9.60 | 20 | 6.20 | 37 | 2.80 |
| 4 | 9.40 | 21 | 6.00 | 38 | 2.60 |
| 5 | 9.20 | 22 | 5.80 | 39 | 2.40 |
| 6 | 9.00 | 23 | 5.60 | 40 | 2.20 |
| 7 | 8.80 | 24 | 5.40 | 41 | 2.00 |
| 8 | 8.60 | 25 | 5.20 | 42 | 1.80 |
| 9 | 8.40 | 26 | 5.00 | 43 | 1.60 |
| 10 | 8.20 | 27 | 4.80 | 44 | 1.40 |
| 11 | 8.00 | 28 | 4.60 | 45 | 1.20 |
| 12 | 7.80 | 29 | 4.40 | 46 | 1.00 |
| 13 | 7.60 | 30 | 4.20 | 47 | 0.80 |
| 14 | 7.40 | 31 | 4.00 | 48 | 0.60 |
| 15 | 7.20 | 32 | 3.80 | 49 | 0.40 |
| 16 | 7.00 | 33 | 3.60 | 50 | 0.20 |
| 17 | 6.80 | 34 | 3.40 | | |
