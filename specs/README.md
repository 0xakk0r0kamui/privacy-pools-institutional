Wallet integration specifications:
- how unsigned transactions and proof artifacts move through approvals and signing
- what policy and allowlist checks are expected in custody systems
- what metadata and logs are needed to support audits and operations

## scope
- A wallet-agnostic custody flow: build unsigned tx -> approvals -> signing -> broadcast -> archive artifacts.
- Requirements for allowlists and constraints (contracts, methods, policies) at a capability level
- Required metadata fields for approval and audit logs


## tasks
- [ ] Canonical custody flow spec (roles, steps, artifacts at each step)
- [ ] Allowlist/constraint checklist for production use
- [ ] Metadata and logging requirements (what to record, where it should live)
- [ ] Fireblocks mapping: what must be supported and how to represent transactions/metadata
- [ ] Ledger Enterprise mapping: what signers must see and what constraints apply

## expectations

- [ ] The documents define responsibilities and artifacts in plain terms: what is prepared, what is approved, what is signed, and what is retained.
- [ ] Vendor sections are mappings, not redesigns.
- [ ] The spec includes what must be captured when an approval is rejected, a reference is outdated, or an artifact is missing.
