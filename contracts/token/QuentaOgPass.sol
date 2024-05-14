// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * @author Quenta Technologies Limited
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../core/Delegatable.sol";

contract QuentaOgPass is UUPSUpgradeable, OwnableUpgradeable, ERC721Upgradeable, Delegatable {

    mapping(address => bool) public mintHouse;
    mapping(address => uint256) public binding;
    uint256 public nextTokenId;

    error InvalidData();
    error NonMintHouse();
    error CannotBind();
    error CannotUnbind();
    error CannotTransfer();

    event Bind(address indexed user, uint256 indexed tokenId);
    event Unbind(address indexed user, uint256 indexed tokenId);

    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
        __ERC721_init("QUENTA OG PASS", "QOGP");
        nextTokenId = 1;
    }

    function setMintHouse(address[] calldata houses, bool[] calldata status) external onlyOwner {
        if (houses.length != status.length) revert InvalidData();
        unchecked {
            for (uint256 i; i < houses.length; ++i) {
                mintHouse[houses[i]] = status[i];
            }
        }
    }

    function mint(address user) external {
        if (!mintHouse[msg.sender]) revert NonMintHouse();
        _mint(user, nextTokenId++);
    }

    function bind(uint256 tokenId) external {
        address user = msgSender();
        if (ownerOf(tokenId) != user || binding[user] != 0) revert CannotBind();
        binding[user] = tokenId;
        emit Bind(user, tokenId);
    }

    function unbind() external {
        address user = msgSender();
        uint256 id = binding[user];
        if (id == 0) revert CannotUnbind();
        binding[user] = 0;
        emit Unbind(user, id);
    }

    function _beforeTokenTransfer(address from, address, uint256 firstTokenId, uint256) internal view override {
        if (binding[from] == firstTokenId) revert CannotTransfer();
    }


    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}