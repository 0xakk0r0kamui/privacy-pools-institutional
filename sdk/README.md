TypeScript SDK:
- prepare inputs for proof generation (off-chain)
- package outputs for on-chain verification
- produce unsigned transactions and metadata for custody approval flows

## scope
- Stable request/response types for the canonical flow (deposit -> withdraw).
- A prover interface so different proving backends can be used without changing app code
- Utilities to build unsigned transactions for deposits/withdrawals
- A small explain output that summarizes what the proof/transaction is meant to attest to, for logging and approvals
- Example scripts and integration tests for the canonical flow

## tasks
- [ ] Core types + encoding rules (stable and versioned)
- [ ] Prover abstraction + one concrete backend 
- [ ] Unsigned-tx builders for deposit/withdraw
- [ ] Explain output + trace IDs/hashes for linking off-chain logs to on-chain actions
- [ ] Examples + integration tests (happy path + common failure paths)

## expectations
- [ ] SDK can be used as a dependency in another codebase without pulling in project-specific assumptions (stable exports, clear types, clear versioning).
- [ ] SDK outputs are custody-friendly: it produces unsigned transaction payloads plus a short, stable summary that can be logged and attached to approvals.
- [ ] SDK does not embed policy decisions; it only carries policy references provided by the caller
- [ ] Failures identify what is wrong (inputs, missing references, proof verification mismatch) without dumping sensitive material