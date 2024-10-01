// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "script/Constants.sol";

import {Delay} from "@delay-module/Delay.sol";
import {Roles} from "@roles-module/Roles.sol";
import {Bouncer} from "@gnosispay-kit/Bouncer.sol";

import {Enum} from "lib/delay-module/node_modules/@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import {ISafe} from "@gnosispay-kit/interfaces/ISafe.sol";

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

import {ICurveStableSwap} from "src/interfaces/ICurveStableSwap.sol";

contract BaseFixture is Test {
    uint256 initBal = 1000 ether;

    // gnosis pay modules
    Delay delayModule;
    Roles rolesModule;

    Bouncer bouncerContract;

    ISafe safe;

    ICurveStableSwap curveBreadWxdai;
    // ICurveStableSwap curveBreadWxdai;

    // Keeper address (forwarder): https://docs.chain.link/chainlink-automation/guides/forwarder#securing-your-upkeep
    address keeper;

    function setUp() public virtual {
        vm.createSelectFork("gnosis");

        curveBreadWxdai = ICurveStableSwap(CURVE_LP_WXDAI_BREAD);
        // CURVE_LP_EURE_USD

        deal(GNOSIS_BREAD, GNOSIS_SAFE, initBal);
    }

    function testGetSafe() public {
        uint256 initMoneriumBalance = IERC20(GNOSIS_EURE).balanceOf(GNOSIS_SAFE);
        uint256 txAmount = 10 ether;

        vm.prank(GNOSIS_SAFE);
        IERC20(GNOSIS_EURE).transfer(address(this), txAmount);

        uint256 newMoneriumBalance = IERC20(GNOSIS_EURE).balanceOf(GNOSIS_SAFE);
        assertEq(initMoneriumBalance - txAmount, newMoneriumBalance);
    }

    function testReadCurveBreadWxdai() public {
        uint256 exchangeAmount = 100 ether;

        // send 100 WXDAI, recieve approx. 101 BREAD
        uint256 amountX = curveBreadWxdai.get_dx(0, 1, exchangeAmount);
        assertGt(amountX, exchangeAmount);

        // send 100 BREAD, recieve approx. 99 WXDAI
        uint256 amountY = curveBreadWxdai.get_dy(0, 1, exchangeAmount);
        assertGt(amountY, exchangeAmount - 1 ether);
    }

    function testExchangeBreadForWxdai() public {
        uint256 exchangeAmount = 100 ether;
        require(IERC20(GNOSIS_BREAD).balanceOf(GNOSIS_SAFE) >= exchangeAmount);

        vm.startPrank(GNOSIS_SAFE);
        IERC20(GNOSIS_BREAD).approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        // send 100 BREAD, recieve 99 WXDAI
        uint256 amountY = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether);
        vm.stopPrank();

        assertGt(amountY, exchangeAmount - 1 ether);
    }

    function testExchangeBreadForWxdai() public {
        uint256 exchangeAmount = 100 ether;
        require(IERC20(GNOSIS_BREAD).balanceOf(GNOSIS_SAFE) >= exchangeAmount);

        vm.startPrank(GNOSIS_SAFE);
        IERC20(GNOSIS_BREAD).approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        // send 100 BREAD, recieve 99 WXDAI
        uint256 amountWxdai = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether);
        // send 99 WXDAI, recieve 89 EURE
        // uint256 amountEure = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether);

        vm.stopPrank();

        assertGt(amountY, exchangeAmount - 1 ether);
    }
}
