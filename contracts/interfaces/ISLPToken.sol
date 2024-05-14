// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ISLPToken is IERC20Metadata {
    function mint(address account, uint256 amount) external;
    
    function burn(uint256 amount) external;
}