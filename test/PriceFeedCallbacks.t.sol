// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PriceFeed.sol";
import "./MockOracleRequester.sol";

contract PriceFeedTest is Test {
    using stdStorage for StdStorage;

    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed(1, 2, 5000000000);
        MockOracleRequester requester = new MockOracleRequester("somebytes");
        priceFeed.setOracleRequester(requester);
        priceFeed.addOracle(
            0x57B6611dE36d8C093cA1c01E054dB301d8e092F5,
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.addOracle(
            0xB5DB0Eb39522427f292F4aeCA62B7886639BE8Da,
            "159fc6b02a3c4904866f83dde78e5a1e"
        );
    }

    function testInitialCallback() public {
        priceFeed.updatePrice();
        priceFeed.receivePrice("req1", 1000000);
        assertEq(
            0,
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.updatesReceived(), 1);
    }

    function testEnoughCallbacksReceived() public {
        vm.warp(1680000);
        priceFeed.receivePrice("req1", 1000000);
        priceFeed.receivePrice("req2", 1200000);
        assertEq(
            1100000,
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.lastUpdatedTimestamp(), 1680000);
        assertEq(priceFeed.updatesReceived(), 0);
    }

    function bytes32ToString(bytes32 _bytes32)
        public
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
