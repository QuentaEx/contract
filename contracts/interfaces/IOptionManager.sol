// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

interface IOptionManager {
    function baseTokenAddress() external returns (address);

    function moveToNextEpoch(uint256 _currentEpochEndTime) external;
}