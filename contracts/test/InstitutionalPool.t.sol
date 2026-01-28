// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {AssociationSetRegistry} from "../src/AssociationSetRegistry.sol";
import {InstitutionalPool} from "../src/InstitutionalPool.sol";
import {MockComplianceVerifier} from "../src/test/MockComplianceVerifier.sol";
import {MockERC20} from "../src/test/MockERC20.sol";

contract InstitutionalPoolReplayTest {
    function testReplayProtection() public {
        AssociationSetRegistry registry = new AssociationSetRegistry();
        MockComplianceVerifier verifier = new MockComplianceVerifier();
        MockERC20 token = new MockERC20("Mock Token", "MOCK");
        InstitutionalPool pool = new InstitutionalPool(address(registry), address(verifier), bytes32("policy"));

        uint256 setId = 1;
        bytes32 root = keccak256(abi.encodePacked("root"));
        registry.createSet(setId, root);

        token.mint(address(this), 100);
        token.approve(address(pool), 100);
        pool.deposit(address(token), 100);

        bytes32 withdrawalId = keccak256(abi.encodePacked("withdrawal"));
        pool.withdraw(address(token), 10, address(this), setId, "", "", withdrawalId);

        bool reverted = false;
        try pool.withdraw(address(token), 10, address(this), setId, "", "", withdrawalId) {
            // no-op
        } catch {
            reverted = true;
        }

        assert(reverted);
    }
}
