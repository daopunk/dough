// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.25;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {ICurveStableSwap, ICurveStableSwapV2} from "src/interfaces/ICurveStableSwap.sol";

interface IDough {
    event RefillBalance(address _safe, uint256 _breadExchanged, uint256 _eureRecieved);

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
    uint256 constant WAD = 1 ether;
    IERC20 constant GNOSIS_EURE = IERC20(0xcB444e90D8198415266c6a2724b7900fb12FC56E);
    IERC20 constant GNOSIS_BREAD = IERC20(0xa555d5344f6FB6c65da19e403Cb4c1eC4a1a5Ee3);
    ICurveStableSwap constant CRV_WXDAI_BREAD = ICurveStableSwap(0xf3D8F3dE71657D342db60dd714c8a2aE37Eac6B4);
    ICurveStableSwap constant CRV_WXDAI_USDC_USDT = ICurveStableSwap(0x7f90122BF0700F9E7e1F688fe926940E8839F353);
    ICurveStableSwapV2 constant CRV_EURE_USD = ICurveStableSwapV2(0x056C6C5e684CeC248635eD86033378Cc444459B0);

    uint256 internal _counter; // set limit for address(this) to limit array-based DOS (out of gas) attack

    mapping(address safe => SafeSettings) _safeSettings;

    address[] internal _safeRegistry;

    function addSafeToRegistry() external {
        // confirm Safe is associated with Gnosis Pay, add Safe to data structures, add max approvals
        _counter += 1;
    }

    function automatedPowerPoolCall() public view returns (bool, bytes memory _payload) {
        address[] memory _safes;
        uint256[] memory _amounts;

        for (uint256 i; i < _counter; i++) {
            address _safe = _safeRegistry[i];
            SafeSettings memory ss = _safeSettings[_safe];

            if (GNOSIS_EURE.balanceOf(_safe) < ss.refillTrigger) {
                uint256 _amount = (ss.refillAmount - GNOSIS_EURE.balanceOf(_safe)) * WAD / CRV_EURE_USD.price_oracle();

                if (GNOSIS_BREAD.balanceOf(_safe) > _amount) {
                    _safes[i] = _safe;
                    _amounts[i] = _amount;
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
            address _safe = _safes[i];
            uint256 _amount = _amounts[i];

            GNOSIS_BREAD.transferFrom(_safe, address(this), _amount);
            uint256 _wxdai = CRV_WXDAI_BREAD.exchange(0, 1, _amount, _amount * 0.97 ether / WAD); // minimum 97% exchange rate

            // TODO: make calldata?
            uint256[] memory _lp3usd = new uint256[](3);
            _lp3usd[0] = _wxdai;
            uint256 _3usd = CRV_WXDAI_USDC_USDT.add_liquidity(_lp3usd, _wxdai * 0.97 ether / WAD);
            uint256 _eure = CRV_EURE_USD.exchange(1, 0, _3usd, _3usd * CRV_EURE_USD.price_oracle() / WAD, _safe);

            emit RefillBalance(_safe, _amount, _eure);
        }
    }
}
