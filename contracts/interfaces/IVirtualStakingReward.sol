// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.19;

interface IVirtualStakingReward {
    function stake(uint256 tokenId, uint256 share) external;
    function unlock(uint256 tokenId) external;
    function claim(uint256 tokenId) external;
}