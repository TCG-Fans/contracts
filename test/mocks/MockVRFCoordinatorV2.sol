// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";

contract MockVRFCoordinatorV2 is VRFCoordinatorV2_5Mock {
    uint96 constant MOCK_BASE_FEE = 100000000000000000;
    uint96 constant MOCK_GAS_PRICE_LINK = 1e9;
    int256 constant WEI_PER_UNIT_LINK = 1e18;

    constructor()
        VRFCoordinatorV2_5Mock(
            MOCK_BASE_FEE,
            MOCK_GAS_PRICE_LINK,
            WEI_PER_UNIT_LINK
        )
    {}
}
