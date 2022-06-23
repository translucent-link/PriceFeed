// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/PriceFeed.sol";

contract PriceFeedOwnershipTest is Test {
    PriceFeed priceFeed;

    function setUp() public {
        priceFeed = new PriceFeed(1, 2);
    }

    function testNotOwnerAddOracle() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        priceFeed.addOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434),
            "159fc6b02a3c4904866f83dde78e5a1f"
        );
    }

    function testNotOwnerRemoveOracle() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        priceFeed.removeOracle(
            address(0x188b71C9d27cDeE01B9b0dfF5C1aff62E8D6F434)
        );
    }

    function testNotOwnerSetMinimumOracles() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        priceFeed.setMinimumOracles(2);
    }

    function testNotOwnerSetMaximumOracles() public {
        vm.prank(address(0));
        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        priceFeed.setMaximumOracles(2);
    }
}