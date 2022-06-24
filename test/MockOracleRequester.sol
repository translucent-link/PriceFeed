// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/Node.sol";
import "../src/OracleRequester.sol";

contract MockOracleRequester is OracleRequester {
    bytes32 public returnableRequestId;
    address public requestedOracle;
    string public requestedJobId;
    uint256 public requestedPayment;
    bytes4 public requestedSelector;
    uint256 public noCalls;

    constructor(bytes32 _returnableRequestId) {
        returnableRequestId = _returnableRequestId;
    }

    function makeRequestToNode(
        Node memory _node,
        uint256 _payment,
        bytes4 _selector
    ) external returns (bytes32 requestId) {
        noCalls++;
        requestedOracle = _node.oracle;
        requestedJobId = _node.jobId;
        requestedPayment = _payment;
        requestedSelector = _selector;

        requestId = returnableRequestId;
    }
}
