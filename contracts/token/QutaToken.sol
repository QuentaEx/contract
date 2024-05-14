// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract QutaToken is UUPSUpgradeable, ERC20Upgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    function initialize(uint256 _totalSupply) external initializer {
        __ERC20_init("Quenta", "QUTA");
        __Ownable_init();

        _mint(msg.sender, _totalSupply);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
