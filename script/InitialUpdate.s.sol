// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Cardpool} from "../src/Cardpool.sol";

contract CounterScript is Script {
    Cardpool public cardpool =
        Cardpool(0xdcBf6f32F80172A9Ae9bD0E12D04904f6daCE46E);
    Cardpool.Card[] initial;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        initial.push(Cardpool.Card(65537, 2));
        initial.push(Cardpool.Card(65538, 2));
        initial.push(Cardpool.Card(65539, 2));
        initial.push(Cardpool.Card(65540, 2));
        initial.push(Cardpool.Card(65547, 2));
        initial.push(Cardpool.Card(65548, 2));
        initial.push(Cardpool.Card(65549, 2));
        initial.push(Cardpool.Card(65550, 2));
        initial.push(Cardpool.Card(65557, 2));
        initial.push(Cardpool.Card(65558, 2));
        initial.push(Cardpool.Card(65559, 2));
        initial.push(Cardpool.Card(65560, 2));
        initial.push(Cardpool.Card(65567, 2));
        initial.push(Cardpool.Card(65568, 2));
        initial.push(Cardpool.Card(65569, 2));
        initial.push(Cardpool.Card(65570, 2));

        cardpool.updateInitialSet(initial);

        vm.stopBroadcast();
    }
}
