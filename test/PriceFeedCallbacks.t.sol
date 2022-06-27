// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PriceFeed.sol";
import "./MockOracleRequester.sol";
import "./MockLINK.sol";
import "./MockOracle.sol";

contract PriceFeedTest is Test {
    using stdStorage for StdStorage;

    PriceFeed priceFeed;
    LinkToken linkToken;
    bytes32 requestId1;
    bytes32 requestId2;

    function setUp() public {

        linkToken = new LinkToken();
        mockOracle1 = MockOracle(linkToken.address);
        mockOracle2 = MockOracle(linkToken.address);

        priceFeed = new PriceFeed(1, 2, 5000000000);
        MockOracleRequester requester = new MockOracleRequester("somebytes");
        priceFeed.setOracleRequester(requester);
        priceFeed.addOracle(
            mockOracle1.address,
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.addOracle(
            mockOracle2.address,
            "159fc6b02a3c4904866f83dde78e5a1e"
        );
    }

    function testInitialCallback() public {
        priceFeed.updatePrice();
        byrtes32 requestId = priceFeed.requestIds[0];   
        priceFeed.requestCallback(requestId, 1000000);
        assertEq(
            0,
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.updatesReceived(), 1);
    }

    function testEnoughCallbacksReceived() public {
        vm.warp(1680000);
        priceFeed.requestCallback("abc123", 1000000);
        priceFeed.requestCallback("abc123", 1200000);
        assertEq(
            1100000,
            priceFeed.price(),
            "Expecting price to be 0. Need another oracle answer"
        );
        assertEq(priceFeed.lastUpdatedTimestamp(), 1680000);
        assertEq(priceFeed.updatesReceived(), 0);
    }

    // function testInitialCallback2() public {
    //     stdstore
    //         .target(address(priceFeed))
    //         .sig("pendingRequests()")
    //         .with_key("abc123")
    //         .checked_write(address(this));

    //     priceFeed.requestCallback("abc123", 1000000);
    //     assertEq(1000000, priceFeed.price(), "Expecting price to be 1000000");
    // }
}
