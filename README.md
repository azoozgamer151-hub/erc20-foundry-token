# FairToken: a trust-minimized ERC-20 with Foundry tests

![tests](https://github.com/azoozgamer151-hub/erc20-foundry-token/actions/workflows/test.yml/badge.svg)

A clean ERC-20 token built with **Solidity 0.8.24**, **OpenZeppelin v5** and **Foundry**,
designed so buyers don't have to trust the deployer.

The whole supply is minted **once** at deployment, and the contract deliberately has
**no owner, no mint function, no transfer tax, no blacklist and no pause**.
Those are the levers behind most rug pulls and honeypots, so this token simply doesn't have them.

## Features
- Fixed supply, minted once to a chosen recipient
- `burn` / `burnFrom` (holders can burn their own tokens)
- EIP-2612 `permit` (gasless approvals)
- Custom errors for invalid deployment (zero recipient / zero supply)

## Tests (15 passing)
| Type | What it proves |
|---|---|
| Unit | metadata, supply, transfers, approvals, burn, permit signatures, revert cases |
| "No hidden powers" | there is no `owner()`, no `mint()`, no tax, and any holder can always sell |
| Fuzz (1,000 runs) | random transfers never change total supply |
| Invariant (8,192 random calls) | balances always sum to total supply; supply only decreases through burns |

```
Suite result: ok. 13 passed; 0 failed   (FairTokenTest)
Suite result: ok. 2 passed; 0 failed    (FairTokenInvariantTest, 128 runs x 64 calls)
```

## Run it
```bash
git clone --recursive https://github.com/azoozgamer151-hub/erc20-foundry-token
cd erc20-foundry-token
forge test -vv
```

## Deploy (testnet)
```bash
TOKEN_NAME="Fair Token" TOKEN_SYMBOL=FAIR TOKEN_SUPPLY=1000000 \
forge script script/Deploy.s.sol --rpc-url $RPC_URL --account deployer --broadcast
```
Works on any EVM chain (Ethereum, Base, Arbitrum, BSC...). Use a keystore account
(`cast wallet import deployer --interactive`) instead of pasting private keys.

## What a buyer should check in any token
This repo's tests double as a checklist:
1. Can the owner mint new tokens? (dilution)
2. Is there a buy/sell tax, and can it be changed later?
3. Can addresses be blacklisted, or can trading be paused? (honeypot)
4. Is ownership renounced, or held by a multisig?
5. Is the source code verified on the block explorer?

## Structure
```
src/FairToken.sol                  the token
test/FairToken.t.sol               unit + fuzz tests
test/FairToken.invariant.t.sol     invariant tests with a handler
script/Deploy.s.sol                deployment script
```

## License
MIT
