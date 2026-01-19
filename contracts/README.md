
auditable contracts:
- deposit ERC-20 into the pool
- withdraw only when a compliance proof verifies
- emit events that record deposits, withdrawals, and policy-relevant changes

## scope
- Minimal ERC-20 flow with deposit and withdraw.
- On-chain verifies proofs; proof generation is off-chain
- Reference an association set by set ID / root 
- Admin actions for set/verifier/policy updates, with on-chain logging
- Tests focused on invariants and expected failure paths


## tasks
- [ ] Pool core + withdrawal proof verification hook.
- [ ] Set reference + update mechanism (authority + events)
- [ ] Event schema for deposits, withdrawals, and set/verifier/policy changes
- [ ] Invariants & tests: prevent replay/double-withdraw; reject unknown set roots; enforce policy 

## expectations
- [ ] The contract set is deployable and readable as a single unit: ownership, roles, and permissions are clear from code and from on-chain state
- [ ] The on-chain record is self-describing at the level institutions care about: it is possible to tell which policy context applied to a withdrawal, and when that context changed
- [ ] Administrative actions are limited to what is needed, and each such action leaves a chain-visible record that can be linked to later outcomes
- [ ] Failure behavior is consistent: invalid inputs fail early and do not produce partial state changes.
- [ ] Tests cover the core safety properties and the most likely operator mistakes (misconfigured policy/set reference, replay attempts, invalid proof inputs)
