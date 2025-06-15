// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {Cardpool} from "../src/Cardpool.sol";

contract CounterScript is Script {
    Cardpool public cardpool;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        cardpool = new Cardpool(
            0xcD8415372BCB0ACfD685367251e215A3C5D8A845,
            0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE,
            0xc799bd1e3bd4d1a41cd4968997a4e03dfd2a3c7c04b695881138580163f42887,
            39161161074640330053606877108131729328056542957027787937910387644884101147139,
            1,
            500_000,
            1e17,
            2e17,
            ""
        );

        vm.stopBroadcast();
    }
}
