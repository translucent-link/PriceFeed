// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface PriceReceiverInterface {
    function receivePrice(bytes32 _requestId, uint256 _price) external;
}
