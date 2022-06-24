// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";
import "./Node.sol";
import "./OracleRequester.sol";

contract ChainlinkOracleRequester is ChainlinkClient, OracleRequester {
    function makeRequestToNode(
        Node memory _node,
        uint256 _payment,
        bytes4 _selector
    ) external returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            stringToBytes32(_node.jobId),
            address(this),
            _selector
        );

        requestId = sendChainlinkRequestTo(_node.oracle, req, _payment);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
