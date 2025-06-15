// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract Payments {
    IERC20 _token;

    constructor(address token) {
        _token = IERC20(token);
    }

    function processPayment(uint256 amount, address payee) internal {
        // Check user's balance
        require(_token.balanceOf(payee) >= amount, "Insufficient balance");

        // Check allowance
        require(
            _token.allowance(payee, address(this)) >= amount,
            "Insufficient allowance"
        );

        bool success = _token.transferFrom(payee, address(this), amount);
        require(success, "Transfer failed");
    }
}
