
## Setup

```bash
cd contracts
npm install
```

## Build / Test / Export

```bash
# compile (Hardhat)
npm run build

# Hardhat tests
npm test

# Foundry tests (requires Foundry installed)
npm run forge:test

# export ABI + TypeChain types
npm run export
```

## Notes

- Hardhat reads `foundry.toml` for the solc version and optimizer runs to keep settings aligned.
- ABI exports land in `exports/abi/` and TypeChain output in `exports/types/`.
