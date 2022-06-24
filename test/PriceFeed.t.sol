// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PriceFeed.sol";
import "./MockOracleRequester.sol";

contract PriceFeedTest is Test {
    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed(1, 2, 5000000000);
    }

    function testSetPayment() public {
        priceFeed.setPayment(2);
        assert(priceFeed.payment() == 2);
    }

    function testNoOracles() public {
        assertTrue(priceFeed.noOracles() == 0, "Expected no oracles");
    }

    function testAddBadOracle() public {
        vm.expectRevert(bytes("Oracle cannot be 0x0"));
        priceFeed.addOracle(address(0), "");
    }

    function testAddOracle() public {
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        assertTrue(priceFeed.noOracles() == 1, "Expected 1 oracle");
    }

    function testRemoveBadOracle() public {
        vm.expectRevert(bytes("Oracle not added"));
        priceFeed.removeOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434)
        );
    }

    function testRemoveOracle() public {
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.removeOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434)
        );
        assertTrue(priceFeed.noOracles() == 0, "Expected 0 oracles");
    }

    function testSetMinimumOraclesReduceBelowCurrentNotAllowed() public {
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        vm.expectRevert(
            bytes("Unable to set minimum oracles, increase current oracles")
        );
        priceFeed.setMinimumOracles(2);
    }

    function testSetMinimumOracles() public {
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.addOracle(
            address(0x1f3C37A25AF4Aa9D43a2fC336b8D3fbC0da0c11C),
            "159fc6b02a3c4904866f83dde78e5a1e"
        );
        priceFeed.setMinimumOracles(1);
        assertEq(1, priceFeed.minimumOracles(), "Expected 1 minimum oracle");
    }

    function testSetMaximumOraclesBelowCurrentNotAllowed() public {
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.addOracle(
            address(0x1f3C37A25AF4Aa9D43a2fC336b8D3fbC0da0c11C),
            "159fc6b02a3c4904866f83dde78e5a1e"
        );
        vm.expectRevert(bytes("Unable to set maximum, reduce current oracles"));
        priceFeed.setMaximumOracles(1);
    }

    function testMakeOracleRequests() public {
        MockOracleRequester requester = new MockOracleRequester("somebytes");
        priceFeed.setOracleRequester(requester);
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
        priceFeed.addOracle(
            address(0x1f3C37A25AF4Aa9D43a2fC336b8D3fbC0da0c11C),
            "159fc6b02a3c4904866f83dde78e5a1e"
        );
        priceFeed.updatePrice();

        assertEq(2, requester.noCalls(), "Expected 1 call");
        assertEq(
            address(0x1f3C37A25AF4Aa9D43a2fC336b8D3fbC0da0c11C),
            requester.requestedOracle(),
            "Expected last oracle address"
        );
        assertEq(
            "159fc6b02a3c4904866f83dde78e5a1e",
            requester.requestedJobId(),
            "Expected last jobId"
        );
        assertEq(
            5000000000,
            requester.requestedPayment(),
            "Expected payment = 5000000000"
        );
        // assertEq(20000, requester.requestedSelector(), "Expected selector");
    }
}
