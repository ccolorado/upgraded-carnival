//SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;
pragma solidity ^0.8.17;

// import { IMockPriceFeedOracle } from "MockPriceFeedOracle.sol";
import { IMockPriceFeedOracle } from "./MockPriceFeedOracle.sol";

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error InvalidCumulativeWeight(uint256 weight);
error ZeroTokenAddress();

contract WeightedIndex is ERC20, Ownable {

    // PriceFeedContract
    IMockPriceFeedOracle public priceOracle;

    // Token addresses and weights
    IERC20 public token1;
    IERC20 public token2;

    uint256 public weight1;
    uint256 public weight2;
    uint256 public token1Price;
    uint256 public token2Price;

    // Events to log important actions
    event Rebalanced(uint256 newWeight1, uint256 newWeight2);
    event PricesUpdated(uint256 newToken1Price, uint256 newToken2Price);

    /**
    * @dev Initializes the contract with two tokens and their respective weights.
    * @param _token1 address Address of the first token.
    * @param _token2 address Address of the second token.
    * @param _weight1 uint256 Weight of the first token (in basis points, e.g., 5000 for 50%).
    * @param _weight2 uint256 Weight of the second token (in basis points, e.g., 5000 for 50%).
    * @param _priceOracle address Adress of the priceOracle contract.
    */
    constructor(
            address _token1, address _token2, uint256 _weight1, uint256 _weight2, address _priceOracle
        ) ERC20("WeightedIndex", "WI") {

        require(_token1 != address(0) && _token2 != address(0), "Invalid token address");
        require(_weight1 + _weight2 == 10000, "Total weight must be 100%");

        priceOracle = IMockPriceFeedOracle(_priceOracle);
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
        weight1 = _weight1;
        weight2 = _weight2;
    }

    /**
    * @dev Updates the prices for the tokens from the mock price oracle.
    */
    function updatePrices() external onlyOwner {
        token1Price = priceOracle.getPrice(address(token1));
        token2Price = priceOracle.getPrice(address(token2));
        emit PricesUpdated(token1Price, token2Price);
    }

    /**
    * @dev Calculates the current index value based on token prices from the oracle and weights.
    * @return indexValue The current index value.
    */
    function getIndexValue() public view returns (uint256 indexValue) {
        uint256 _token1Price = priceOracle.getPrice(address(token1));
        uint256 _token2Price = priceOracle.getPrice(address(token2));

        uint256 token1Value = (_token1Price * token1.balanceOf(address(this)) * weight1) / 10000;
        uint256 token2Value = (_token2Price * token2.balanceOf(address(this)) * weight2) / 10000;

        indexValue = token1Value + token2Value;
    }

    /**
    * @dev Rebalances the token weights.
    * @param newWeight1 uint256 New weight for the first token.
    * @param newWeight2 uint256 New weight for the second token.
    */
    function rebalance(uint256 newWeight1, uint256 newWeight2) external onlyOwner {
        require(newWeight1 + newWeight2 == 10000, "Total weight must be 100%");
        weight1 = newWeight1;
        weight2 = newWeight2;
        emit Rebalanced(newWeight1, newWeight2);
    }

    /**
    * @dev Mints index tokens.
    * @param amount uint256 The amount of index tokens to mint.
    */
    function mint(uint256 amount) external onlyOwner {
        _mint(msg.sender, amount);
    }

    /**
    * @dev Burns index tokens.
    * @param amount uint256 The amount of index tokens to burn.
    */
    function burn(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
    }

}
