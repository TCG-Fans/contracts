// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Coin} from "../src/Coin.sol";

contract CounterScript is Script {
    Coin public coin;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        coin = new Coin();

        vm.stopBroadcast();
    }
}
