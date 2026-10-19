# TRUSTCOIN (TRUST) — Who Is a Holder

Token: `0xfDe6a8FA6658e59EfD07dEBe3d0bd073F820D293` (Ethereum mainnet)

Short version. Full rules: [TRUSTCOIN_LOYALTY_REWARDS.md](TRUSTCOIN_LOYALTY_REWARDS.md).

## The main rule

**Buy 1,000 TRUST or more, keep them in your own wallet, and never send anything out of that wallet until the snapshot after the 50th monthly release.**

- **999.99 TRUST is not a holder.** A wallet enters the first time its balance reaches 1,000 TRUST.
- **After entry, any outbound transfer disqualifies the wallet forever (the "Guillotine").** A sale, a transfer to a friend, a transfer to your own other wallet, a deposit to an exchange — even 1 wei. There is no re-entry.
- **Before entry**, movements do not count against you.
- **You can buy more at any time.** Incoming TRUST never hurts you.

## Limits

| Rule | Until | After |
|---|---|---|
| Maximum 10,000 TRUST per wallet | June 1, 2027, 00:00 UTC | no limit — buy as much as you want |
| Transfers between regular wallets must be at least 1,000 TRUST | the 50th monthly release | any amount |
| Uniswap v4 pool | no minimum from day one | — |

## Your weight

- Every purchase carries the **G-weight of the month it was bought**: 10.0 in month 1 down to 0.2 in month 50.
- "Month" = the number of `monthlyRelease()` calls executed before your purchase, not a calendar month.
- **Your points = Σ (coins in each purchase × G of its month).** At the snapshot your share is fixed forever: your points ÷ the points of all qualified holders.
- Table: [TRUSTCOIN_COEFFICIENT_G.md](TRUSTCOIN_COEFFICIENT_G.md).

## How not to lose holder status

1. **Keep your tokens in your own wallet, not on an exchange.** Tokens on an exchange belong to the exchange.
2. **Never send anything from your holder wallet.** If you want to trade, use a separate wallet.
3. **Leave a margin.** Transfers between regular wallets and purchases in the V2 pool carry a 0.5% fee: send 1,000 and 995 arrive — that wallet has not entered. Make sure the balance reaches 1,000 **after** fees.

## Who is not counted

Contracts (exchange pools, the auction, vaults), exchange addresses, and the project's own service wallets are excluded from the snapshot.

---

*How the Loyalty Vault works will be announced several months before it launches. The exact snapshot script, exclusion list and data will be published so anyone can verify them. This is not investment advice.*
