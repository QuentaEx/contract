// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * @author Quenta Technologies Limited
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

error VirtualStakingReward__NotOwner();
error VirtualStakingReward__ProvidedRewardTooHigh();
error VirtualStakingReward__InvalidCaller();

contract VirtualStakingReward is UUPSUpgradeable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StakedPosition {
        uint256 share;
        uint256 rewardPerSharePaid;
        uint256 reward;
    }

    IERC20Upgradeable public rewardToken;
    uint256 public duration;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;
    uint256 public historicalRewards;

    uint256 public totalShare;
    mapping(uint256 => StakedPosition) public positions;

    address public mainReward;

    event RewardAdded(uint256 reward);
    event RewardPaid(uint256 indexed tokenId, uint256 reward);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        IERC20Upgradeable reward_,
        uint256 duration_,
        address mainReward_
    ) external initializer {
        __Ownable_init();

        duration = duration_;
        rewardToken = reward_;
        mainReward = mainReward_;
    }

    function notifyRewardAmount(uint256 _reward) external onlyOwner {
        _updateReward(0);
        historicalRewards += _reward;
        if (block.timestamp >= periodFinish) {
            rewardRate = _reward / duration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (_reward + leftover) / duration;
        }

        uint256 balance = rewardToken.balanceOf(address(this));
        if (rewardRate > balance / duration) revert VirtualStakingReward__ProvidedRewardTooHigh();

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;
        emit RewardAdded(_reward);
    }

    function _updateReward(uint256 tokenId) internal {
        rewardPerShareStored = rewardPerShare();
        lastUpdateTime = lastTimeRewardApplicable();
        if (tokenId != 0) {
            StakedPosition storage position = positions[tokenId];
            position.reward = earned(tokenId);
            position.rewardPerSharePaid = rewardPerShareStored;
        }
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardPerShare() public view returns (uint256) {
        if (totalShare == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalShare;
    }

    function earned(uint256 tokenId) public view returns (uint256) {
        StakedPosition storage position = positions[tokenId];
        return (position.share * (rewardPerShare() - position.rewardPerSharePaid)) / 1e18 + position.reward;
    }

    function stake(uint256 tokenId, uint256 share) external {
        if (msg.sender != mainReward) revert VirtualStakingReward__InvalidCaller();
        _updateReward(0);
        totalShare += share;
        StakedPosition storage position = positions[tokenId];
        position.rewardPerSharePaid = rewardPerShare();
        position.share = share;
    }

    function unlock(uint256 tokenId) external {
        if (msg.sender != mainReward) revert VirtualStakingReward__InvalidCaller();
        StakedPosition storage position = positions[tokenId];
        claim(tokenId);
        totalShare -= position.share;
        delete positions[tokenId];
    }

    function claim(uint256 tokenId) public {
        address user = IERC721(mainReward).ownerOf(tokenId);
        _updateReward(tokenId);
        StakedPosition storage position = positions[tokenId];
        uint256 reward = position.reward;
        position.reward = 0;
        rewardToken.safeTransfer(user, reward);

        emit RewardPaid(tokenId, reward);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}