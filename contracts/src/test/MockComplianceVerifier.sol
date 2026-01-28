// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IComplianceVerifier} from "../IComplianceVerifier.sol";

contract MockComplianceVerifier is IComplianceVerifier {
    bool public accept = true;

    function setAccept(bool accept_) external {
        accept = accept_;
    }

    function verify(bytes calldata, bytes calldata) external view returns (bool) {
        return accept;
    }
}
