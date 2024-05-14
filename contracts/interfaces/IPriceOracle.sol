// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

interface IPriceOracle {
    function validatePrice(address product, uint256 subproduct, uint256 price) external view;
}