// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error DToken__InvalidData();
error DToken__TransferToNonwhitelisted();

contract DToken is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable {

    mapping(address => bool) public whitelist;

    constructor() {
        _disableInitializers();
    }

    function initialize(string memory _name, string memory _symbol, uint256 _totalSupply) external initializer {
        __ERC20_init(_name, _symbol);
        __Ownable_init();

        whitelist[address(0)] = true;
        _mint(msg.sender, _totalSupply);
    }

    function updateWhitelist(address[] calldata addresses, bool[] calldata status) external onlyOwner {
        if (addresses.length != status.length) revert DToken__InvalidData();
        unchecked {
            for (uint256 i; i < addresses.length; ++i) {
                whitelist[addresses[i]] = status[i];
            }
        }
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal view override {
        if (!whitelist[from] && !whitelist[to]) revert DToken__TransferToNonwhitelisted();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
