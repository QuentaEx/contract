// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

interface IFutureConfig {
    function getConfig(bytes32 key, uint256 futureId) external view returns (uint256);
}