// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "script/Constants.sol";

import {Delay} from "@delay-module/Delay.sol";
import {Roles} from "@roles-module/Roles.sol";
import {Bouncer} from "@gnosispay-kit/Bouncer.sol";

import {Enum} from "lib/delay-module/node_modules/@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

import {ISafe} from "@gnosispay-kit/interfaces/ISafe.sol";

contract BaseFixture is Test {
    // gnosis pay modules
    Delay delayModule;
    Roles rolesModule;

    Bouncer bouncerContract;

    ISafe safe;

    // Keeper address (forwarder): https://docs.chain.link/chainlink-automation/guides/forwarder#securing-your-upkeep
    address keeper;

    function setUp() public virtual {
        vm.createSelectFork("gnosis");
    }

    function testGetSafe() {}
}
