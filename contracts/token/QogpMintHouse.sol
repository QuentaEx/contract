// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * @author Quenta Technologies Limited
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IQuentaOgPass {
    function mint(address user) external;
    function nextTokenId() external view returns (uint256);
}

contract QogpMintHouse is UUPSUpgradeable, OwnableUpgradeable {

    uint256 public startTime;
    uint256 public endTime;
    uint256 public nftAmount;
    bytes32 public merkleRoot;
    address public ogPass;

    mapping(address => bool) public minted;

    error AlreadyMinted();
    error InvalidProof();
    error Timeout();
    error AmountExceeded();

    event MintPass(address indexed user);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _ogPass, uint256 _startTime, uint256 _endTime, uint256 _nftAmount, bytes32 _root) external initializer {
        __Ownable_init();

        startTime = _startTime;
        endTime = _endTime;
        nftAmount = _nftAmount;
        merkleRoot = _root;
        ogPass = _ogPass;
    }

    function setRoot(bytes32 _root) external onlyOwner {
        merkleRoot = _root;
    }

    function mint(bytes32[] calldata proof) external {
        if (block.timestamp < startTime || block.timestamp > endTime) revert Timeout();
        if (IQuentaOgPass(ogPass).nextTokenId() > nftAmount) revert AmountExceeded();
        if (minted[msg.sender]) revert AlreadyMinted();
        if (MerkleProof.verifyCalldata(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) revert InvalidProof();
        IQuentaOgPass(ogPass).mint(msg.sender);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}