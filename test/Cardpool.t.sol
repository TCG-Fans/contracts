// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Cardpool} from "../src/Cardpool.sol";
import {Coin} from "../src/Coin.sol";
import {MockVRFCoordinatorV2} from "./mocks/MockVRFCoordinatorV2.sol";
import {console} from "forge-std/console.sol";

contract CardpoolTest is Test {
    Cardpool public cardpool;
    Coin public coin;
    MockVRFCoordinatorV2 public vrfCoordinator;
    uint256 subId;
    bytes32 keyHash;
    uint96 constant FUND_AMOUNT = 1 * 10 ** 18;

    function setUp() public {
        coin = new Coin();
        coin.mint(1e21);
        vrfCoordinator = new MockVRFCoordinatorV2();
        subId = vrfCoordinator.createSubscription();

        vrfCoordinator.fundSubscription(subId, FUND_AMOUNT);
        Cardpool.Card[] memory initialSet = new Cardpool.Card[](3);
        initialSet[0] = Cardpool.Card(1, 1);
        initialSet[1] = Cardpool.Card(2, 1);
        initialSet[2] = Cardpool.Card(3, 1);

        cardpool = new Cardpool(
            address(coin),
            address(vrfCoordinator),
            keyHash,
            subId,
            1,
            1_000_000,
            1e19,
            3e19,
            ""
        );
        vrfCoordinator.addConsumer(subId, address(cardpool));

        cardpool.addExtenstion(0, 100, 30, 20);

        cardpool.addExtenstion(1, 40, 16, 8);
    }

    function test_MintPack() public {
        address mintTo = makeAddr("mintPack");
        coin.transfer(mintTo, 1e20);
        Cardpool.Card[] memory cardsBeforeMint = cardpool.userCards(mintTo);
        assertEq(cardsBeforeMint.length, 0);
        uint256 balance = coin.balanceOf(mintTo);
        assertEq(balance, 1e20);
        vm.startPrank(mintTo);
        coin.approve(address(cardpool), 1e19);
        uint256 requestId = cardpool.mintPack(0, mintTo, false);
        console.logUint(requestId);
        vm.stopPrank();

        vrfCoordinator.fulfillRandomWords(requestId, address(cardpool));
        Cardpool.Card[] memory cardsAfterMint = cardpool.userCards(mintTo);
        assertTrue(cardsAfterMint.length > 0);
        uint quantity = 0;
        for (uint i = 0; i < cardsAfterMint.length; i++) {
            console.logUint(cardsAfterMint[i].id);
            quantity += cardsAfterMint[i].quantity;
        }
        assertEq(quantity, 8);
        uint256 balanceAfter = coin.balanceOf(mintTo);
        assertEq(balanceAfter, 1e20 - 1e19);
    }

    // function test_MintInitial() public {
    //     address mintTo = makeAddr("mintInitial");
    //     coin.transfer(mintTo, 1e20);
    //     Cardpool.Card[] memory cardsBeforeMint = cardpool.userCards(mintTo);
    //     assertEq(cardsBeforeMint.length, 0);
    //     uint256 balance = coin.balanceOf(mintTo);
    //     assertEq(balance, 1e20);
    //     vm.startPrank(mintTo);
    //     coin.approve(address(cardpool), 5e19);
    //     cardpool.mintInitial(mintTo);
    //     vm.stopPrank();

    //     Cardpool.Card[] memory cardsAfterMint = cardpool.userCards(mintTo);
    //     assertTrue(cardsAfterMint.length > 0);
    //     uint quantity = 0;
    //     for (uint i = 0; i < cardsAfterMint.length; i++) {
    //         quantity += cardsAfterMint[i].quantity;
    //     }
    //     assertEq(quantity, 3);
    //     uint256 balanceAfter = coin.balanceOf(mintTo);
    //     assertEq(balanceAfter, 1e20 - 3e19);
    // }

    function test_MintPackNextExtension() public {
        uint32 k = 1;
        uint32 d = k << 16;
        console.logUint(d);
        address mintTo = makeAddr("mintPack");
        coin.transfer(mintTo, 1e20);
        Cardpool.Card[] memory cardsBeforeMint = cardpool.userCards(mintTo);
        assertEq(cardsBeforeMint.length, 0);
        uint256 balance = coin.balanceOf(mintTo);
        assertEq(balance, 1e20);
        vm.startPrank(mintTo);
        coin.approve(address(cardpool), 1e19);
        uint256 requestId = cardpool.mintPack(1, mintTo, false);
        console.logUint(requestId);
        vm.stopPrank();

        vrfCoordinator.fulfillRandomWords(requestId, address(cardpool));
        Cardpool.Card[] memory cardsAfterMint = cardpool.userCards(mintTo);
        assertTrue(cardsAfterMint.length > 0);
        uint quantity = 0;
        for (uint i = 0; i < cardsAfterMint.length; i++) {
            console.logUint(cardsAfterMint[i].id);
            quantity += cardsAfterMint[i].quantity;
        }
        assertEq(quantity, 8);
        uint256 balanceAfter = coin.balanceOf(mintTo);
        assertEq(balanceAfter, 1e20 - 1e19);
    }
}
