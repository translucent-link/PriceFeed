// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Node.sol";

interface OracleRequesterInterface {
    function makeRequestToNode(Node memory _node, uint256 _payment)
        external
        returns (bytes32);
}
