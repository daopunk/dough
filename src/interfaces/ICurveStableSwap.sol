// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface ICurveStableSwap is IERC20 {
    /**
     * @dev Returns the name of the token
     */
    function name() external returns (string memory);

    /**
     * @dev Returns the symbol of the token
     */
    function symbol() external returns (string memory);

    /**
     * @dev Add liquidity to a Curve pool
     */
    function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

    /**
     * @dev Get amount of received token X in swap for Y (send Y, receive X)
     * @notice token order is irrelevant
     */
    function get_dx(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    /**
     * @dev Get amount of received token Y in swap for X (send X, receive Y)
     * @notice token order is irrelevant
     */
    function get_dy(int128 i, int128 j, uint256 exchangeAmount) external returns (uint256);

    function exchange(int128 i, int128 j, uint256 exchangeAmount, uint256 minReceiveAmount)
        external
        returns (uint256);

    function exchange(int128 i, int128 j, uint256 exchangeAmount, uint256 minReceiveAmount, address receiver)
        external
        returns (uint256);
}