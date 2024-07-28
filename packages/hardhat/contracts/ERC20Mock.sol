// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20Mock
 * @dev This contract is a mock ERC20 token used for testing purposes.
 */
contract ERC20Mock is ERC20 {
    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param initialSupply Initial supply of the token.
     */
    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}

