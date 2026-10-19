# TRUSTCOIN (TRUST) — Who Is a Holder

Token: `0xfDe6a8FA6658e59EfD07dEBe3d0bd073F820D293` (Ethereum mainnet)

## The main rule

**A holder is a wallet that holds 1,000 TRUST or more and has not sent out a single token during the 50 months of emission.**

- **999 TRUST is not a holder.** 1,000 and above is a holder.
- **Send even one token out of the wallet and your holding period resets to zero (the "guillotine").** A sale, a transfer to a friend, a transfer to your own other wallet, and a deposit to an exchange all count the same.
- **You can buy more at any time.** Incoming transfers never reset your holding period.

## Time-based limits

| Rule | Until | After |
|---|---|---|
| Maximum 10,000 TRUST per wallet | June 1, 2027, 00:00 UTC | no limit, buy as much as you want |
| Transfers between regular wallets must be at least 1,000 TRUST | the 50th emission release (not earlier than Sept 29, 2030) | any amount |
| Uniswap v4 pool | no minimum from day one | — |

## How not to lose holder status

1. **Keep your tokens in your own wallet, not on an exchange.** Tokens on an exchange belong to the exchange, not to you.
2. **Never send anything from your holder wallet.** If you want to trade, use a separate wallet.
3. **Leave a margin.** Transfers between regular wallets and purchases in the V2 pool carry a 0.5% fee: send 1,000 and 995 arrive — that is no longer a holder. Keep at least 1,000 in the wallet **after** all fees.
4. **Time matters.** Tokens acquired earlier carry more weight (a coefficient from 10.0 in month 1 down to 0.2 in month 50). Tokens bought later are weighted by the month in which they arrived.

## What a holder receives

After the 50th emission release, a snapshot of all holders is taken. Each holder receives a share of the distribution: 80% of the tax revenue collected by TaxBridge goes to the Loyalty Vault and is split among holders according to the snapshot.

How the Loyalty Vault works will be announced several months before it launches.

## Who is not counted as a holder

Contracts (exchange pools, the auction, vaults), exchange addresses, and the project's own service wallets are excluded from the snapshot.

---

*This document describes the current rules. The exact snapshot rules (script, exclusion list, data) will be published before the Loyalty Vault launches so that anyone can verify them. This is not investment advice.*
