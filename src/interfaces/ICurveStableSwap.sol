// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ICurveStableSwap is IERC20, IERC20Metadata {
    /**
     * @dev Get token address by index
     */
    function coins(uint256 i) external returns (address);

    /**
     * @dev Add liquidity to a Curve 2pool
     */
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @dev Add liquidity to a Curve 3pool
     */
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @dev Get amount of received token X in swap for Y (send Y, receive X)
     */
    function get_dx(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    /**
     * @dev Get amount of received token Y in swap for X (send X, receive Y)
     */
    function get_dy(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    /**
     * @dev Exchange i for j
     */
    function exchange(int128 i, int128 j, uint256 exchangeAmount, uint256 minReceiveAmount)
        external
        returns (uint256);

    /**
     * @dev Exchange i for j with receiver
     */
    function exchange(int128 i, int128 j, uint256 exchangeAmount, uint256 minReceiveAmount, address receiver)
        external
        returns (uint256);
}

interface ICurveStableSwapV2 is IERC20, IERC20Metadata {
    /**
     * @dev Get token address by index
     */
    function coins(uint256 i) external returns (address);

    /**
     * @dev Add liquidity to a Curve 2pool
     */
    function add_liquidity(uint256[2] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @dev Add liquidity to a Curve 3pool
     */
    function add_liquidity(uint256[3] calldata _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @dev Get amount of received token X in swap for Y (send Y, receive X)
     */
    function get_dx(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    /**
     * @dev Get amount of received token Y in swap for X (send X, receive Y)
     */
    function get_dy(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    /**
     * @dev Exchange i for j
     */
    function exchange(uint256 i, uint256 j, uint256 exchangeAmount, uint256 minReceiveAmount)
        external
        returns (uint256);

    /**
     * @dev Exchange i for j with receiver
     */
    function exchange(uint256 i, uint256 j, uint256 exchangeAmount, uint256 minReceiveAmount, address receiver)
        external
        returns (uint256);
}
