// SPDX-License-Identifier: UNLICENSED

/*
 * Quenta Exchange Contracts
 * Copyright (C) 2024 Quenta
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract QuentaProxy is ERC1967Proxy {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {
    }
}