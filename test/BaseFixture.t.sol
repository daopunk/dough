// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "script/Constants.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {Dough, IDough} from "src/Dough.sol";

// import {Delay} from "@delay-module/Delay.sol";
// import {Roles} from "@roles-module/Roles.sol";
// import {Bouncer} from "@gnosispay-kit/Bouncer.sol";
// import {Enum} from "lib/delay-module/node_modules/@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import {ISafe} from "@gnosispay-kit/interfaces/ISafe.sol";
import {ICurveStableSwap, ICurveStableSwapV2} from "src/interfaces/ICurveStableSwap.sol";

uint256 constant INIT_BAL = 1000 ether;
uint256 constant INIT_EURE = 250 ether;
uint256 constant WAD = 1 ether;

contract BaseFixture is Test {
    ICurveStableSwapV2 public curveEureUsd;

    IERC20 public bread;
    IERC20 public wxdai;
    IERC20 public eure;
    IERC20 public crv_3usd;

    function setUp() public virtual {
        vm.createSelectFork("gnosis");
        deal(GNOSIS_BREAD, GNOSIS_SAFE, INIT_BAL);
        curveEureUsd = ICurveStableSwapV2(CURVE_LP_EURE_USD);

        bread = IERC20(GNOSIS_BREAD);
        wxdai = IERC20(GNOSIS_WXDAI);
        eure = IERC20(GNOSIS_EURE);
        crv_3usd = IERC20(GNOSIS_3CRV_WXDAI_USDC_USDT);
    }

    function testByteArray() public {
        bytes memory byteArray1 = bytes("abcdefghijklmnpqrstuvwxyz");
        bytes memory byteArray2 = bytes(byteArray1[4:8]);
        emit log_bytes(byteArray1);
        emit log_bytes(byteArray2);
    }
}

contract Test_Dough is BaseFixture {
    uint256 constant LOWER = 200 ether;
    uint256 constant UPPER = 300 ether;
    uint256 constant MAX_REGISTRY = 1000;
    uint256 constant SPEND_AMOUNT = 25 ether;
    address constant POS = address(0x420);

    IDough public dough;

    uint256 public slippage;

    function setUp() public override {
        super.setUp();
        dough = new Dough(MAX_REGISTRY);
        slippage = dough.SLIPPAGE() * curveEureUsd.price_oracle() / WAD ** 2;

        deal(GNOSIS_3CRV_WXDAI_USDC_USDT, address(this), INIT_BAL);
        crv_3usd.approve(CURVE_LP_EURE_USD, INIT_BAL);
        curveEureUsd.exchange(1, 0, INIT_BAL, slippage);
        eure.transfer(GNOSIS_SAFE, INIT_EURE - eure.balanceOf(GNOSIS_SAFE));
    }

    function _mockAutomation() internal {
        (bool _proceed, bytes memory _payloadWithSelector) = dough.automatedPowerPoolCall();

        if (_proceed) {
            emit log_string("PREPARE PAYLOAD");

            emit log_named_bytes("PAYLOAD WITH SELECTOR", _payloadWithSelector);

            // (, bytes memory _payload) = abi.decode(_payloadWithSelector, (bytes4, bytes));
            (bytes4 _selector, bytes memory _payload) = _decodeWithSelector(_payloadWithSelector);
            emit log_named_bytes32("SELECTOR", bytes32(_selector));
            emit log_named_bytes("PAYLOAD", _payload);
            emit log_string("EXECUTE RESOLVER");
            dough.resolveRefillBalances(_payload);
            // dough.resolveRefillBalances(_payloadWithSelector);
        } else {
            emit log_string("TERMINATE");
        }
    }

    function _mockGnosisPaySpend(uint256 _amount) internal {
        vm.prank(GNOSIS_SAFE);
        eure.transfer(POS, _amount);
    }

    function _decodeWithSelector(bytes memory _data) internal returns (bytes4, bytes memory) {
        uint256 BYTE_SHIFT = 0x44;
        uint256 _bytesSize = _data.length - BYTE_SHIFT;
        bytes memory _dataWithoutSelector = new bytes(_bytesSize);

        for (uint8 i = 0; i < _bytesSize; i++) {
            _dataWithoutSelector[i] = _data[i + BYTE_SHIFT];
        }
        bytes4 _selector = bytes4(_data);

        emit log_bytes(_dataWithoutSelector);
        return (_selector, _dataWithoutSelector);
    }

    function testSetup() public view {
        assertEq(bread.balanceOf(GNOSIS_SAFE), INIT_BAL);
        assertEq(eure.balanceOf(GNOSIS_SAFE), INIT_EURE);
    }

    function testRegister() public {
        assertEq(dough.counter(), 0);
        vm.prank(GNOSIS_SAFE);
        dough.register(LOWER, UPPER);

        assertEq(dough.counter(), 1);
        (uint256 _s1, uint256 _s2) = dough.safeSettings(GNOSIS_SAFE);
        assertEq(_s1, LOWER);
        assertEq(_s2, UPPER);
    }

    function testAutomation() public {
        vm.startPrank(GNOSIS_SAFE);
        bread.approve(address(dough), type(uint256).max);
        dough.register(LOWER, UPPER);
        vm.stopPrank();

        _mockGnosisPaySpend(SPEND_AMOUNT);
        _mockAutomation();
        assertEq(eure.balanceOf(GNOSIS_SAFE), INIT_EURE - SPEND_AMOUNT);

        _mockGnosisPaySpend(SPEND_AMOUNT);
        _mockAutomation();
        assertEq(eure.balanceOf(GNOSIS_SAFE), INIT_EURE - SPEND_AMOUNT * 2);

        _mockGnosisPaySpend(1);
        assertEq(eure.balanceOf(GNOSIS_SAFE), LOWER - 1);
        _mockAutomation();
        assertApproxEqRel(eure.balanceOf(GNOSIS_SAFE), UPPER, 0.999 ether); // 99.9 accuracy
    }

    // function testAutomationMultiple() public {
    //     vm.startPrank(GNOSIS_SAFE);
    //     bread.approve(address(dough), type(uint256).max);
    //     dough.register(LOWER, UPPER);
    //     vm.stopPrank();

    //     vm.prank(address(0x421));
    //     dough.register(LOWER + 1, UPPER + 1);

    //     vm.prank(address(0x422));
    //     dough.register(LOWER - 1, UPPER - 1);

    //     _mockGnosisPaySpend(SPEND_AMOUNT);
    //     _mockAutomation();
    //     assertEq(eure.balanceOf(GNOSIS_SAFE), INIT_EURE - SPEND_AMOUNT);

    //     _mockGnosisPaySpend(SPEND_AMOUNT);
    //     _mockAutomation();
    //     assertEq(eure.balanceOf(GNOSIS_SAFE), INIT_EURE - SPEND_AMOUNT * 2);

    //     _mockGnosisPaySpend(1);
    //     assertEq(eure.balanceOf(GNOSIS_SAFE), LOWER - 1);
    //     _mockAutomation();
    //     assertApproxEqRel(eure.balanceOf(GNOSIS_SAFE), UPPER, 0.999 ether); // 99.9 accuracy
    // }
}
// 0xfcf2fcb6
// 0000000000000000000000000000000000000000000000000000000000000020
// 00000000000000000000000000000000000000000000000000000000000000c0
// 0000000000000000000000000000000000000000000000000000000000000040
// 0000000000000000000000000000000000000000000000000000000000000080
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000447874194fe1110a4d14488995340f890c51a930
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000000000000000000000000005ff28ca8409de9b6b

// 0x
// 0000000000000000000000000000000000000000000000000000000000000040
// 0000000000000000000000000000000000000000000000000000000000000080
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000447874194fe1110a4d14488995340f890c51a930
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000000000000000000000000005fe5e94fcf29ea8f5

// 0xfcf2fcb6
// 0000000000000000000000000000000000000000000000000000000000000020
// 00000000000000000000000000000000000000000000000000000000000000e0
// 0000000000000000000000000000000000000000000000000000000000000001
// 0000000000000000000000000000000000000000000000000000000000000060
// 00000000000000000000000000000000000000000000000000000000000000a0
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000447874194fe1110a4d14488995340f890c51a930
// 0000000000000000000000000000000000000000000000000000000000000001
// 000000000000000000000000000000000000000000000005ff23fbada69c4887

// 0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000447874194fe1110a4d14488995340f890c51a9300000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000005fe781e23693e5b60
// 0x000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000447874194fe1110a4d14488995340f890c51a9300000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000005fe5868b7f3c98398
// 0x00000000000000000000000000000000000000000000000000000001000000000000000000000000447874194fe1110a4d14488995340f890c51a9300000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000005fe5868b7f3c98398
