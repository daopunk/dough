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

import {ICurveStableSwap, ICurveStableSwapV2} from "src/interfaces/ICurveStableSwap.sol";

uint256 constant INIT_BAL = 1000 ether;

contract BaseFixture is Test {
    // gnosis pay modules
    Delay delayModule;
    Roles rolesModule;

    Bouncer bouncerContract;

    ISafe safe;

    ICurveStableSwap curveBreadWxdai;
    ICurveStableSwap curve3Usd;
    ICurveStableSwapV2 curveEureUsd;

    // Keeper address (forwarder): https://docs.chain.link/chainlink-automation/guides/forwarder#securing-your-upkeep
    address keeper;

    uint256[3] public liquidity3Pool;

    function setUp() public virtual {
        vm.createSelectFork("gnosis");

        curveBreadWxdai = ICurveStableSwap(CURVE_LP_WXDAI_BREAD);
        curve3Usd = ICurveStableSwap(CURVE_LP_WXDAI_USDC_USDT);
        curveEureUsd = ICurveStableSwapV2(CURVE_LP_EURE_USD);

        deal(GNOSIS_BREAD, GNOSIS_SAFE, INIT_BAL);
    }
}

contract Test_CurveFi is BaseFixture {
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
        // send 100 BREAD, recieve 99 WXDAI
        IERC20(GNOSIS_BREAD).approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        uint256 amountY = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether);
        vm.stopPrank();

        assertGt(amountY, exchangeAmount - 1 ether);
    }

    function testExchangeBreadForEure() public {
        uint256 exchangeAmount = 100 ether;
        uint256 initWxdaiBal = IERC20(GNOSIS_WXDAI).balanceOf(GNOSIS_SAFE);
        uint256 initEureBal = IERC20(GNOSIS_EURE).balanceOf(GNOSIS_SAFE);
        require(IERC20(GNOSIS_BREAD).balanceOf(GNOSIS_SAFE) >= exchangeAmount);

        vm.startPrank(GNOSIS_SAFE);
        // send 100 BREAD, recieve 99 WXDAI
        IERC20(GNOSIS_BREAD).approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        uint256 amountWxdai = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(IERC20(GNOSIS_WXDAI).balanceOf(GNOSIS_SAFE), amountWxdai + initWxdaiBal);

        // addLiquidity 99 WXDAI, recieve lpTokens
        IERC20(GNOSIS_WXDAI).approve(CURVE_LP_WXDAI_USDC_USDT, exchangeAmount);
        liquidity3Pool[0] = amountWxdai;
        uint256 amount3Usd = curve3Usd.add_liquidity(liquidity3Pool, amountWxdai - 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(IERC20(GNOSIS_3CRV_WXDAI_USDC_USDT).balanceOf(GNOSIS_SAFE), amount3Usd);

        IERC20(GNOSIS_3CRV_WXDAI_USDC_USDT).approve(CURVE_LP_EURE_USD, amount3Usd);
        uint256 amountEure = curveEureUsd.exchange(1, 0, amount3Usd, 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(IERC20(GNOSIS_EURE).balanceOf(GNOSIS_SAFE), amountEure + initEureBal);

        emit log_named_uint("wxDAI: 100 => EURe", amountEure);
        vm.stopPrank();
    }
}

contract Test_PowerPool is BaseFixture {
    function setUp() public override {
        super.setUp();
    }
}
