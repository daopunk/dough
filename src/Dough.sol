// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ICurveStableSwap, ICurveStableSwapV2} from "src/interfaces/ICurveStableSwap.sol";

interface IDough {
    struct SafeSettings {
        uint256 refillTrigger;
        uint256 refillAmount;
    }

    function resolveRefillBalances(bytes memory _params) external;
}

/**
 * TODO:
 * 1. add add Gnosis Pay Safe addr and verify it is a Gnosis Pay Safe
 */
contract Dough is IDough {
    IERC20 constant GNOSIS_EURE = IERC20(0xcB444e90D8198415266c6a2724b7900fb12FC56E);
    IERC20 constant GNOSIS_BREAD = IERC20(0xa555d5344f6FB6c65da19e403Cb4c1eC4a1a5Ee3);
    ICurveStableSwapV2 constant CRV_EURE_USD = ICurveStableSwapV2(0x056C6C5e684CeC248635eD86033378Cc444459B0);

    uint256 internal _counter; // set limit for address(this) to limit array-based DOS (out of gas) attack

    mapping(address safe => SafeSettings) _safeSettings;

    address[] internal _safeRegistry;

    // function resolveRefillBalances(address[] memory _safes) external view {
    //     uint256 l = _safes.length;
    //     for (uint256 i = 0; i < l; i++) {
    //         resolveRefillBalance(_safes[i]);
    //     }
    // }

    function addSafeToRegistry() external {
        _counter += 1;
    }

    function automatedPowerPoolCall() public view returns (bool, bytes memory _payload) {
        address[] memory _safes;
        uint256[] memory _amounts;

        for (uint256 i; i < _counter; i++) {
            address _safe = _safeRegistry[i];
            SafeSettings memory ss = _safeSettings[_safe];

            if (GNOSIS_EURE.balanceOf(_safe) < ss.refillTrigger) {
                // calculate exchange rate
                uint256 _priceUsdToEure = CRV_EURE_USD.price_oracle();
                uint256 _refillAmount = (ss.refillAmount - GNOSIS_EURE.balanceOf(_safe)) * _priceUsdToEure / 1 ether;

                if (GNOSIS_BREAD.balanceOf(_safe) > _refillAmount) {
                    _safes[i] = _safe;
                    _amounts[i] = _refillAmount;
                }
            }
        }

        if (_safes.length > 0) {
            _payload = abi.encodeWithSelector(IDough.resolveRefillBalances.selector, abi.encode(_safes, _amounts));
            return (true, _payload);
        } else {
            return (false, _payload);
        }
    }

    function resolveRefillBalances(bytes memory _payload) public {
        (address[] memory _safes, uint256[] memory _amounts) = abi.decode(_payload, (address[], uint256[]));

        uint256 l = _safes.length;
        for (uint256 i; i < l; i++) {
            // do the swap
        }
    }
}
