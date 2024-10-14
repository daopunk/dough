// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.25;

import "script/Constants.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {BaseFixture} from "test/BaseFixture.t.sol";
import {ICurveStableSwap} from "src/interfaces/ICurveStableSwap.sol";

contract Test_CurveFi is BaseFixture {
    ICurveStableSwap curveBreadWxdai;
    ICurveStableSwap curve3Usd;

    function setUp() public override {
        super.setUp();
        curveBreadWxdai = ICurveStableSwap(CURVE_LP_WXDAI_BREAD);
        curve3Usd = ICurveStableSwap(CURVE_LP_WXDAI_USDC_USDT);
    }

    function testGetSafe() public {
        uint256 initMoneriumBalance = eure.balanceOf(GNOSIS_SAFE);
        uint256 txAmount = 10 ether;

        vm.prank(GNOSIS_SAFE);
        eure.transfer(address(this), txAmount);

        uint256 newMoneriumBalance = eure.balanceOf(GNOSIS_SAFE);
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
        require(bread.balanceOf(GNOSIS_SAFE) >= exchangeAmount);

        vm.startPrank(GNOSIS_SAFE);
        // send 100 BREAD, recieve 99 WXDAI
        bread.approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        uint256 amountY = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether);
        vm.stopPrank();

        assertGt(amountY, exchangeAmount - 1 ether);
    }

    function testExchangeBreadForEure() public {
        uint256 exchangeAmount = 100 ether;
        uint256 initWxdaiBal = wxdai.balanceOf(GNOSIS_SAFE);
        uint256 initEureBal = eure.balanceOf(GNOSIS_SAFE);
        require(bread.balanceOf(GNOSIS_SAFE) >= exchangeAmount);

        vm.startPrank(GNOSIS_SAFE);
        // send 100 BREAD, recieve 99 WXDAI
        bread.approve(CURVE_LP_WXDAI_BREAD, exchangeAmount);
        uint256 amountWxdai = curveBreadWxdai.exchange(0, 1, exchangeAmount, exchangeAmount - 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(wxdai.balanceOf(GNOSIS_SAFE), amountWxdai + initWxdaiBal);

        // addLiquidity 99 WXDAI, recieve lpTokens
        wxdai.approve(CURVE_LP_WXDAI_USDC_USDT, exchangeAmount);
        uint256 amount3Usd = curve3Usd.add_liquidity([amountWxdai, 0, 0], amountWxdai - 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(crv_3usd.balanceOf(GNOSIS_SAFE), amount3Usd);

        crv_3usd.approve(CURVE_LP_EURE_USD, amount3Usd);
        uint256 amountEure = curveEureUsd.exchange(1, 0, amount3Usd, 1 ether); // todo add proper exchange rate weighted limitations
        assertEq(eure.balanceOf(GNOSIS_SAFE), amountEure + initEureBal);

        emit log_named_uint("wxDAI: 100 => EURe", amountEure);
        vm.stopPrank();
    }
}
