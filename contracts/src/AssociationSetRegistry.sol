// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title AssociationSetRegistry
/// @notice registry for association set roots by id
/// @dev setId is an app-level identifier, root is the commitment (ex: merkle root) for that set
contract AssociationSetRegistry is AccessControl {
    bytes32 public constant SET_MANAGER_ROLE = keccak256("SET_MANAGER_ROLE");

    event SetCreated(uint256 indexed setId, bytes32 root, address indexed actor);
    event SetUpdated(uint256 indexed setId, bytes32 oldRoot, bytes32 newRoot, address indexed actor);

    error InvalidRoot();
    error SetAlreadyExists(uint256 setId);
    error SetUnknown(uint256 setId);

    mapping(uint256 => bytes32) private _roots;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SET_MANAGER_ROLE, msg.sender);
    }

    /// @notice create a new set id -> root mapping
    function createSet(uint256 setId, bytes32 root) external onlyRole(SET_MANAGER_ROLE) {
        if (root == bytes32(0)) revert InvalidRoot();
        if (_roots[setId] != bytes32(0)) revert SetAlreadyExists(setId);

        _roots[setId] = root;
        emit SetCreated(setId, root, msg.sender);
    }

    /// @notice update an existing set id -> root mapping
    function updateSet(uint256 setId, bytes32 newRoot) external onlyRole(SET_MANAGER_ROLE) {
        if (newRoot == bytes32(0)) revert InvalidRoot();

        bytes32 oldRoot = _roots[setId];
        if (oldRoot == bytes32(0)) revert SetUnknown(setId);

        _roots[setId] = newRoot;
        emit SetUpdated(setId, oldRoot, newRoot, msg.sender);
    }

    function getRoot(uint256 setId) external view returns (bytes32) {
        return _roots[setId];
    }

    function isKnown(uint256 setId) external view returns (bool) {
        return _roots[setId] != bytes32(0);
    }
}
