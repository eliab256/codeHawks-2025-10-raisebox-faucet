//SPDX-Lincense-Identifier: MIT

pragma solidity ^0.8.30;

import {Script} from "forge-std/Script.sol";
import {RaiseBoxFaucet} from "../src/RaiseBoxFaucet.sol";

contract DeployRaiseboxContract is Script {
    RaiseBoxFaucet public raiseBox;

    function run() public {
        vm.startBroadcast();
        raiseBox = new RaiseBoxFaucet(
            "raiseboxtoken",
            "RB",
            1000 * 10 ** 18,  //Number of tokens dispensed per claim
            0.005 ether,    //Amount of Sepolia ETH dripped per first-time claim
            1 ether         //Maximum Sepolia ETH distributed per day
        );
        vm.stopBroadcast();
    }
}
