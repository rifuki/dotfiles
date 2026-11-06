# Gas Price

## `wallet gas-price`

Query the three gas price levels (LOW / MEDIUM / HIGH) for a chain.

### Syntax

```bash
baw wallet gas-price --binanceChainId <id> --json
```

### Parameters

| Parameter               | Required | Description                                                  |
|-------------------------|----------|--------------------------------------------------------------|
| `--binanceChainId <id>` | Yes      | Chain id, e.g. `56` (BSC), `1` (Ethereum), `8453` (Base), `CT_501` (Solana) |

### Example

```bash
baw wallet gas-price --binanceChainId 56 --json
```

### Response (EVM)

```json
{
  "success": true,
  "data": {
    "baseFeePerGas": "0",
    "low":    { "gasPrice": "0.053", "maxFeePerGas": "0.053", "maxPriorityFeePerGas": "0.053", "tipAmount": null, "waitTimeEstimate": 16000 },
    "medium": { "gasPrice": "0.054", "maxFeePerGas": "0.054", "maxPriorityFeePerGas": "0.054", "tipAmount": null, "waitTimeEstimate": 8000 },
    "high":   { "gasPrice": "0.055", "maxFeePerGas": "0.055", "maxPriorityFeePerGas": "0.055", "tipAmount": null, "waitTimeEstimate": 3000 }
  }
}
```

### Response (Solana)

```json
{
  "success": true,
  "data": {
    "baseFeePerGas": null,
    "low":    { "gasPrice": "7059",    "maxFeePerGas": null, "maxPriorityFeePerGas": null, "tipAmount": "0.000005",    "waitTimeEstimate": null },
    "medium": { "gasPrice": "123381",  "maxFeePerGas": null, "maxPriorityFeePerGas": null, "tipAmount": "0.000020075", "waitTimeEstimate": null },
    "high":   { "gasPrice": "1003697", "maxFeePerGas": null, "maxPriorityFeePerGas": null, "tipAmount": "0.000164779", "waitTimeEstimate": null }
  }
}
```

### Units

| Chain type | Field                                                            | Unit                                     |
|------------|------------------------------------------------------------------|------------------------------------------|
| EVM        | `gasPrice`, `maxFeePerGas`, `maxPriorityFeePerGas`, `baseFeePerGas` | gwei                                     |
| Solana     | `gasPrice`                                                        | compute unit price (micro-lamports)      |
| Solana     | `tipAmount`                                                       | SOL                                      |
| Both       | `waitTimeEstimate`                                                | milliseconds (null on Solana)            |

EVM-only fields are `null` on Solana, and `tipAmount` is `null` on EVM.

## Important Notes

- **Gas price moves with network conditions.** What you report is a snapshot, not a locked quote.
  Never present it as the final transaction cost — the actual fee is settled when the transaction
  is built and confirmed.
- **Do not multiply it out.** This command returns per-unit prices only; it has no transaction
  context and no gas limit, so any "price × gas limit = fee" figure you compute would be a guess.
  If the user wants an actual cost, run the relevant preview/quote command instead.
- The levels come from the same source the wallet uses when it builds a transaction, but
  prices may change between this query and transaction building.
- **MEDIUM is the default level** for `wallet send`, `market-order swap`, `limit-order buy` /
  `sell`. These commands support `--gasLevel`: suggest `HIGH` only when the user wants faster
  confirmation, and `LOW` when they want to save on fees.
- **`approvals revoke` always uses MEDIUM** and has no gas parameter. Do not suggest changing
  its gas level or pass `--gasLevel`; see [approvals.md](approvals.md).

## When to Use

Run this when the user **asks** about gas — for example:

- "How much is gas on BSC right now?"
- "What's the difference between the fee tiers?"
- "How much more expensive is the fast option?"
- "Is now a good time to trade, gas-wise?"

Do **not** run it before every transaction. Transaction commands already pick the right level on
their own, so a pre-flight gas query just adds a round trip without changing the outcome.

## Errors

| Code     | Meaning                                          | What to tell the user                                     |
|----------|--------------------------------------------------|-----------------------------------------------------------|
| `351734` | The chain does not support gas price queries yet | Gas price lookup isn't available for that network yet.    |
