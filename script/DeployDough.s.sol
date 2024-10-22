// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.25;

import 'forge-std/Script.sol';
import 'forge-std/console.sol';
import {Dough, IDough} from 'src/Dough.sol';

/// @dev simulate deploy to gnosis
// forge script DeployDough --rpc-url "https://rpc.gnosis.gateway.fm" -vvvv

/// @dev deploy to gnosis
// forge script DeployDough --rpc-url "https://rpc.gnosis.gateway.fm" --broadcast -vvvv

contract DeployDough is Script {
    // TODO: adjust `_MAX_REGISTRY` based on gas limitations
    uint256 internal constant _MAX_REGISTRY = 10_000;

    function run() public virtual {
        vm.startBroadcast(vm.envUint('PRIVATE_KEY'));
        new Dough(_MAX_REGISTRY);
        vm.stopBroadcast();
    }
}
