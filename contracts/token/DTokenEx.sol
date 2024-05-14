// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface BurnableERC20 {
    function burn(uint256 amount) external;
}

contract DTokenEx is UUPSUpgradeable, OwnableUpgradeable {
    IERC20Upgradeable public token;
    IERC20Upgradeable public dToken;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _token, address _dToken) external initializer {
        __Ownable_init();
        token = IERC20Upgradeable(_token);
        dToken = IERC20Upgradeable(_dToken);
    }

    function exchange() external {
        uint256 amount = dToken.balanceOf(msg.sender);
        dToken.transferFrom(msg.sender, address(this), amount);
        BurnableERC20(address(dToken)).burn(amount);
        token.transfer(msg.sender, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
