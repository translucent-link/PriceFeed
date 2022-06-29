// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../src/Node.sol";
import "../src/OracleRequesterInterface.sol";

contract MockOracleRequester is OracleRequesterInterface {
    bytes32 public returnableRequestId;
    address public requestedOracle;
    string public requestedJobId;
    uint256 public requestedPayment;
    uint256 public noCalls;

    constructor(bytes32 _returnableRequestId) {
        returnableRequestId = _returnableRequestId;
    }

    function makeRequestToNode(Node memory _node, uint256 _payment)
        external
        returns (bytes32 requestId)
    {
        noCalls++;
        requestedOracle = _node.oracle;
        requestedJobId = _node.jobId;
        requestedPayment = _payment;

        requestId = returnableRequestId;
    }
}
