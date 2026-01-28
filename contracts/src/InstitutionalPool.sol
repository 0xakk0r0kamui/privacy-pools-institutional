// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {AssociationSetRegistry} from "./AssociationSetRegistry.sol";
import {IComplianceVerifier} from "./IComplianceVerifier.sol";

/// @title InstitutionalPool
/// @notice custodial wrapper: deposit in, withdraw out with external compliance checks
contract InstitutionalPool is AccessControl, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant POLICY_MANAGER_ROLE = keccak256("POLICY_MANAGER_ROLE");

    event Deposit(address indexed sender, address indexed token, uint256 amount);
    event Withdrawal(
        address indexed sender,
        address indexed recipient,
        address indexed token,
        uint256 amount,
        uint256 setId,
        bytes32 setRoot,
        bytes32 policyId,
        bytes32 withdrawalId
    );
    event VerifierUpdated(address indexed oldVerifier, address indexed newVerifier, address indexed actor);
    event RegistryUpdated(address indexed oldRegistry, address indexed newRegistry, address indexed actor);
    event PolicyIdUpdated(bytes32 indexed oldPolicyId, bytes32 indexed newPolicyId, address indexed actor);

    error ZeroAddress();
    error InvalidAmount();
    error InvalidRecipient();
    error UnknownSet(uint256 setId);
    error VerificationFailed();
    error WithdrawalAlreadySpent(bytes32 withdrawalId);

    AssociationSetRegistry public registry;
    IComplianceVerifier public verifier;
    bytes32 public policyId;

    mapping(bytes32 => bool) public spent;

    /// @notice init with registry + verifier + policy id
    constructor(address registry_, address verifier_, bytes32 policyId_) {
        if (registry_ == address(0) || verifier_ == address(0)) revert ZeroAddress();

        registry = AssociationSetRegistry(registry_);
        verifier = IComplianceVerifier(verifier_);
        policyId = policyId_;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(POLICY_MANAGER_ROLE, msg.sender);
    }

    function setVerifier(address newVerifier) external onlyRole(POLICY_MANAGER_ROLE) {
        if (newVerifier == address(0)) revert ZeroAddress();

        address oldVerifier = address(verifier);
        verifier = IComplianceVerifier(newVerifier);
        emit VerifierUpdated(oldVerifier, newVerifier, msg.sender);
    }

    function setRegistry(address newRegistry) external onlyRole(POLICY_MANAGER_ROLE) {
        if (newRegistry == address(0)) revert ZeroAddress();

        address oldRegistry = address(registry);
        registry = AssociationSetRegistry(newRegistry);
        emit RegistryUpdated(oldRegistry, newRegistry, msg.sender);
    }

    function setPolicyId(bytes32 newPolicyId) external onlyRole(POLICY_MANAGER_ROLE) {
        bytes32 oldPolicyId = policyId;
        policyId = newPolicyId;
        emit PolicyIdUpdated(oldPolicyId, newPolicyId, msg.sender);
    }

    function pause() external onlyRole(OPERATOR_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(OPERATOR_ROLE) {
        _unpause();
    }

    /// @notice pulls tokens into the pool
    function deposit(address token, uint256 amount) external nonReentrant whenNotPaused {
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit Deposit(msg.sender, token, amount);
    }

    /// @notice withdraw with proof + replay protection
    function withdraw(
        address token,
        uint256 amount,
        address recipient,
        uint256 setId,
        bytes calldata proof,
        bytes calldata publicInputs,
        bytes32 withdrawalId
    ) external nonReentrant whenNotPaused {
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert InvalidAmount();
        if (recipient == address(0)) revert InvalidRecipient();

        bytes32 setRoot = registry.getRoot(setId);
        if (setRoot == bytes32(0)) revert UnknownSet(setId);

        if (spent[withdrawalId]) revert WithdrawalAlreadySpent(withdrawalId);
        if (!verifier.verify(proof, publicInputs)) revert VerificationFailed();

        spent[withdrawalId] = true;
        IERC20(token).safeTransfer(recipient, amount);

        emit Withdrawal(msg.sender, recipient, token, amount, setId, setRoot, policyId, withdrawalId);
    }
}
