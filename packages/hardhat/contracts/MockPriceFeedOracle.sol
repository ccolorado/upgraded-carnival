// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMockPriceFeedOracle {

    function setPrice(address token, uint256 price) external;

    function getPrice(address token) external view returns (uint256);
}

/**
 * @title MockPriceFeedOracle
 * @dev This contract provides a mock price oracle for tokens, used for testing purposes.
 */
contract MockPriceFeedOracle {
    // Mapping from token address to token price
    mapping(address => uint256) private tokenPrices;

    // Event to log price updates
    event PriceUpdated(address indexed token, uint256 newPrice);

    /**
     * @dev Sets the price of a token.
     * @param token address The address of the token.
     * @param price uint256 The price of the token (in wei).
     */
    function setPrice(address token, uint256 price) external {
        tokenPrices[token] = price;
        emit PriceUpdated(token, price);
    }

    /**
     * @dev Gets the price of a token.
     * @param token address The address of the token.
     * @return The price of the token (in wei).
     */
    function getPrice(address token) external view returns (uint256) {
        return tokenPrices[token];
    }
}
