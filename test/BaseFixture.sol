// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

import {Delay} from "delay-module/Delay.sol";
import {Roles} from "@roles-module/Roles.sol";

import {Bouncer} from "../src/helpers/Bouncer.sol";

import {RoboSaverModule} from "../src/RoboSaverModule.sol";

import {ISafe} from "../src/interfaces/safe/ISafe.sol";
import {IEURe} from "../src/interfaces/eure/IEURe.sol";

contract BaseFixture is Test {
    /*//////////////////////////////////////////////////////////////////////////
                                   CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint256 constant EURE_TO_MINT = 1_000e18;

    address constant GNOSIS_SAFE = 0xa4A4a4879dCD3289312884e9eC74Ed37f9a92a55;
    address constant SAFE_EOA_SIGNER = 0x1377aaE47bB2a62f54351Ec36bA6a5313FC5844c;

    // delay config
    uint256 constant COOL_DOWN_PERIOD = 180; // 3 minutes
    uint256 constant EXPIRATION_PERIOD = 1800; // 30 minutes

    // bouncer config
    bytes4 constant SET_ALLOWANCE_SELECTOR =
        bytes4(keccak256(bytes("setAllowance(bytes32,uint128,uint128,uint128,uint64,uint64)"))); // 0xa8ec43ee
    bytes32 constant SET_ALLOWANCE_KEY = keccak256(abi.encode(GNOSIS_SAFE));

    // tokens
    address constant EUR_E = 0xcB444e90D8198415266c6a2724b7900fb12FC56E;
    address constant WETH = 0x6A023CCd1ff6F2045C3309768eAd9E68F978f6e1;

    address constant EUR_E_MINTER = 0x882145B1F9764372125861727d7bE616c84010Ef;

    // gnosis pay modules
    Delay delayModule;
    Roles rolesModule;

    Bouncer bouncerContract;

    ISafe safe;

    // robosaver module
    RoboSaverModule roboModule;

    function setUp() public virtual {
        // https://gnosisscan.io/block/33288902
        vm.createSelectFork("gnosis", 33288902);

        safe = ISafe(payable(GNOSIS_SAFE));

        // module deployments to mirror gnosis pay setup: delay & roles
        delayModule = new Delay(GNOSIS_SAFE, GNOSIS_SAFE, GNOSIS_SAFE, COOL_DOWN_PERIOD, EXPIRATION_PERIOD);

        roboModule = new RoboSaverModule(address(delayModule));

        vm.prank(GNOSIS_SAFE);
        delayModule.enableModule(address(roboModule));

        vm.prank(GNOSIS_SAFE);
        safe.enableModule(address(delayModule));

        vm.prank(EUR_E_MINTER);
        IEURe(EUR_E).mintTo(GNOSIS_SAFE, EURE_TO_MINT);

        vm.label(EUR_E, "EUR_E");
        vm.label(WETH, "WETH");
        vm.label(GNOSIS_SAFE, "GNOSIS_SAFE");
        vm.label(address(delayModule), "DELAY_MODULE");
        vm.label(address(bouncerContract), "BOUNCER_CONTRACT");
        vm.label(address(rolesModule), "ROLES_MODULE");
    }

    function _bouncerAndRoleSetup() internal {
        rolesModule = new Roles(SAFE_EOA_SIGNER, GNOSIS_SAFE, GNOSIS_SAFE);

        vm.prank(GNOSIS_SAFE);
        safe.enableModule(address(rolesModule));

        bouncerContract = new Bouncer(GNOSIS_SAFE, address(rolesModule), SET_ALLOWANCE_SELECTOR);

        // set allowances

        // assign roles

        // scope target

        // scope function

        // transfer ownership
        vm.prank(SAFE_EOA_SIGNER);
        rolesModule.transferOwnership(address(bouncerContract));
    }
}
