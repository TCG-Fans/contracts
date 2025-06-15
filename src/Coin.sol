// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Coin is ERC20("TcCoin", "TCN"), Ownable(msg.sender) {
    function mint(uint256 emission) public onlyOwner {
        _mint(owner(), emission);
    }
}
