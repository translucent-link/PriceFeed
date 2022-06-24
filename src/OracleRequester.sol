// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Node.sol";

interface OracleRequester {
    function makeRequestToNode(
        Node memory _node,
        uint256 _payment,
        bytes4 _selector
    ) external returns (bytes32);
}
