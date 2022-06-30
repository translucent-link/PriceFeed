// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "forge-std/Test.sol";
import "../src/PriceFeed.sol";
import "../src/Math.sol";
import "./MockOracleRequester.sol";

contract PriceFeedTest is Test {
    using stdStorage for StdStorage;

    PriceFeed priceFeed;
    address node1;
    address node2;

    function setUp() public {
        node1 = 0x57B6611dE36d8C093cA1c01E054dB301d8e092F5;
        node2 = 0xB5DB0Eb39522427f292F4aeCA62B7886639BE8Da;

        priceFeed = new PriceFeed(
            1,
            2,
            5000000000,
            0x514910771AF9Ca656af840dff83E8264EcF986CA
        );
        MockOracleRequester requester = new MockOracleRequester("somebytes");
        priceFeed.setOracleRequester(requester);
        priceFeed.addOracle(node1, "159fc6b02a3c4904866f83dde78e5a1f");
        priceFeed.addOracle(node2, "159fc6b02a3c4904866f83dde78e5a1e");
    }

    function testInitialCallback(bytes32 requestId, uint256 price) public {
        priceFeed.updatePrice();
        hoax(node1);
        priceFeed.receivePrice(requestId, price);
        assertEq(
            0,
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.updatesReceived(), 1);
    }

    function testEnoughCallbacksReceived(uint128 price1, uint128 price2)
        public
    {
        uint256[] memory expectedPrices = new uint256[](2);
        expectedPrices[0] = price1;
        expectedPrices[1] = price2;
        vm.warp(1680000);
        hoax(node1);
        priceFeed.receivePrice("req1", price1);
        hoax(node2);
        priceFeed.receivePrice("req2", price2);
        assertEq(
            Math.average(expectedPrices),
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.lastUpdatedTimestamp(), 1680000);
        assertEq(priceFeed.updatesReceived(), 0);
    }

    function testCallbacksWithOverflowPrices() public {
        hoax(node1);
        priceFeed.receivePrice("req1", 1);
        vm.expectRevert(stdError.arithmeticError);
        hoax(node2);
        priceFeed.receivePrice(
            "req2",
            115792089237316195423570985008687907853269984665640564039457584007913129639935
        );
    }
}
