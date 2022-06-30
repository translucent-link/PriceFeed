// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "forge-std/Script.sol";
import "../src/PriceFeed.sol";

contract ContractScript is Script {
    function run() public {
        vm.startBroadcast();

        uint256 minimumOracles = 1;
        uint256 maximumOracles = 2;
        uint256 payment = 5 * 10**16;
        address linkTokenAddress = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;

        PriceFeed feed = new PriceFeed(
            minimumOracles,
            maximumOracles,
            payment,
            linkTokenAddress
        );

        vm.stopBroadcast();
    }
}
