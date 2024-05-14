// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

abstract contract QuentaPausable is OwnableUpgradeable, PausableUpgradeable {
    function __QuentaPausable_init() internal onlyInitializing {
        __Ownable_init();
        __Pausable_init();
    }

    function setPause(bool _paused) external onlyOwner {
        bool current = paused();
        if (_paused && !current) {
            _pause();
        } else if (!_paused && current) {
            _unpause();
        }
    }

    uint256[50] private __gap;
}
