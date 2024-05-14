// SPDX-License-Identifier: BUSL-1.1

/*
 * Quenta Exchange Contracts
 * @author Quenta Technologies Limited
 * Based on Synthetix StakingRewards
 */

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../core/Delegatable.sol";
import "../interfaces/IUserBalance.sol";
import "../interfaces/IVirtualStakingReward.sol";

error StakingReward__InvalidLockTime();
error StakingReward__CannotStakeZero();
error StakingReward__NotOwner();
error StakingReward__ProvidedRewardTooHigh();
error StakingReward__StillLocked();

contract StakingReward is UUPSUpgradeable, ERC721Upgradeable, OwnableUpgradeable, Delegatable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct StakedPosition {
        uint256 amount;
        uint256 share;
        uint256 unlockTime;
        uint256 rewardPerSharePaid;
        uint256 reward;
    }

    IUserBalance public exchangeWallet;
    IERC20Upgradeable public rewardToken;
    IERC20Upgradeable public stakingToken;
    uint256 public duration;

    uint256 public constant BOOST_PRECISION = 10 ** 4;
    uint256 public maxLockupPeriod; // default = 2 * 360 days
    uint256 public minLockupPeriod;
    uint256 public maxBoost;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;
    uint256 public historicalRewards;

    uint256 public nextTokenId;
    string private baseURI;

    uint256 public totalShare;
    mapping(uint256 => StakedPosition) public positions;

    address[] public extraRewards;

    event RewardAdded(uint256 reward);
    event Staked(uint256 indexed tokenId, uint256 amount, uint256 share, uint256 lockupTime);
    event RewardPaid(uint256 indexed tokenId, uint256 reward);
    event Withdrawn(uint256 indexed tokenId, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        IUserBalance exchangeWallet_,
        IERC20Upgradeable stakingToken_,
        IERC20Upgradeable reward_,
        uint256 duration_,
        uint256 maxLockupPeriod_
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __Ownable_init();

        exchangeWallet = exchangeWallet_;
        duration = duration_;
        rewardToken = reward_;
        stakingToken = stakingToken_;
        maxLockupPeriod = maxLockupPeriod_;
        nextTokenId = 1;

        minLockupPeriod = 30 days;
        maxBoost = 12 * BOOST_PRECISION;
    }

    function extraRewardsLength() external view returns (uint256) {
        return extraRewards.length;
    }

    function addExtraReward(address _reward) external onlyOwner {
        require(_reward != address(0), "!reward setting");

        extraRewards.push(_reward);
    }

    function clearExtraRewards() external onlyOwner {
        delete extraRewards;
    }

    function setHub(address hub) external onlyOwner {
        _setHub(hub);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function boostMultiplier(uint256 _lockTime) public view returns (uint256) {
        if (_lockTime < minLockupPeriod || _lockTime > maxLockupPeriod) revert StakingReward__InvalidLockTime();
        return (maxBoost * _lockTime) / maxLockupPeriod;
    }

    function setMinLockupPeriod(uint256 _min) external onlyOwner {
        minLockupPeriod = _min;
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
        if (rewardRate > balance / duration) revert StakingReward__ProvidedRewardTooHigh();

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

    function stake(uint256 amount, uint256 lockupTime) external {
        if (amount == 0) revert StakingReward__CannotStakeZero();
        _updateReward(0);
        address user = msgSender();
        uint256 share = (amount * boostMultiplier(lockupTime)) / BOOST_PRECISION;
        exchangeWallet.transfer(address(stakingToken), user, address(this), amount);
        totalShare += share;
        uint256 tokenId = nextTokenId++;
        StakedPosition storage position = positions[tokenId];
        position.amount = amount;
        position.unlockTime = block.timestamp + lockupTime;
        position.rewardPerSharePaid = rewardPerShare();
        position.share = share;

        emit Staked(tokenId, amount, share, lockupTime);

        _mint(user, tokenId);

        for (uint256 i; i < extraRewards.length; ++i) {
            IVirtualStakingReward(extraRewards[i]).stake(tokenId, share);
        }
    }

    function unlock(uint256 tokenId) external {
        address user = ownerOf(tokenId);
        StakedPosition storage position = positions[tokenId];
        if(block.timestamp < position.unlockTime) revert StakingReward__StillLocked();

        claim(tokenId);

        for (uint256 i; i < extraRewards.length; ++i) {
            IVirtualStakingReward(extraRewards[i]).unlock(tokenId);
        }

        uint256 amount = position.amount;
        position.amount = 0;
        totalShare -= position.share;
        stakingToken.safeTransfer(address(exchangeWallet), amount);
        exchangeWallet.increaseBalance(address(stakingToken), user, amount);

        emit Withdrawn(tokenId, amount);

        _burn(tokenId);
    }

    function claim(uint256 tokenId) public {
        address user = ownerOf(tokenId);
        _updateReward(tokenId);
        StakedPosition storage position = positions[tokenId];
        uint256 reward = position.reward;
        position.reward = 0;
        rewardToken.safeTransfer(user, reward);

        emit RewardPaid(tokenId, reward);

        for (uint256 i; i < extraRewards.length; ++i) {
            IVirtualStakingReward(extraRewards[i]).claim(tokenId);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}