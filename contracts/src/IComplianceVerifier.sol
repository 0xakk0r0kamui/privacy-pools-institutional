// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @notice minimal verifier interface for compliance proofs
interface IComplianceVerifier {
    /// @notice returns true if proof + inputs are valid
    function verify(bytes calldata proof, bytes calldata publicInputs) external view returns (bool);
}
