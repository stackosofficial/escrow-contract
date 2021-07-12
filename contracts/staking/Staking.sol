pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";

contract Staking is Ownable {
    uint256 constant EXP = 10**18;
    uint256 constant DAY = 86400;
    address public stackToken;
    address public dnsClusterStore;
    uint256 public slashFactor;
    uint256 public rewardsPerShare;
    uint256 public rewardsPerUpvote;
    uint256 public stakingAmount;
    uint256 public slashCollected;

    struct Stake {
        uint256 amount;
        uint256 stakedAt;
        uint256 share;
        uint256 lastWithdraw;
        bytes32 dns;
        uint256 lastRewardsCollectedAt;
    }

    mapping(address => Stake) public stakes;

    event SlashCollectedLog(
        address collector,
        uint256 collectedSlash,
        uint256 slashCollectedAt
    );

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of DNSClusterMetadata Store deployed contract
     * @param Address of stackToken deployed contract
     * @param Minimum staking amount
     * @param Slash Factor - Number of rewards be Slashed for bad actors
     * @param Number of rewards for every Upvotes
     * @param Number of rewards for every share of the whole staking pool
     */
    constructor(
        address _dnsClusterStore,
        address _stackToken,
        uint256 _stakingAmount,
        uint256 _slashFactor,
        uint256 _rewardsPerUpvote,
        uint256 _rewardsPerShare
    ) public {
        stackToken = _stackToken;
        dnsClusterStore = _dnsClusterStore;
        stakingAmount = _stakingAmount;
        slashFactor = _slashFactor;
        rewardsPerUpvote = _rewardsPerUpvote;
        rewardsPerShare = _rewardsPerShare;
    }

    /*
     * @title Update the minimum staking amount
     * @param Updated minimum staking amount
     * @dev Could only be invoked by the contract owner
     */
    function setStakingAmount(uint256 _stakingAmount) public onlyOwner {
        stakingAmount = _stakingAmount;
    }

    /*
     * @title Update the Slash Factor
     * @param New slash factor amount
     * @dev Could only be invoked by the contract owner
     */
    function setSlashFactor(uint256 _slashFactor) public onlyOwner {
        slashFactor = _slashFactor;
    }

    /*
     * @title Update the Rewards per Share
     * @param Updated amount of Rewards for each share
     * @dev Could only be invoked by the contract owner
     */
    function setRewardsPerShare(uint256 _rewardsPerShare) public onlyOwner {
        rewardsPerShare = _rewardsPerShare;
    }

    /*
     * @title Users could stake there stack tokens
     * @param Number of stack tokens to stake
     * @param Name of DNS
     * @param IPAddress of the DNS
     * @param whitelisted IP
     * @return True if successfully invoked
     */
    function deposit(
        uint256 _amount,
        bytes32 _dns,
        string memory _ipAddress,
        string memory _whitelistedIps
    ) public returns (bool) {
        require(
            _amount > stakingAmount,
            "Amount should be greater than the stakingAmount"
        );
        Stake storage stake = stakes[msg.sender];
        IERC20(stackToken).transferFrom(msg.sender, address(this), _amount);
        stake.stakedAt = block.timestamp;
        stake.amount = _amount;
        stake.dns = _dns;
        stake.share = _calcStakedShare(_amount, msg.sender);

        // Staking contract creates a ClusterMetadata Entry
        IDnsClusterMetadataStore(dnsClusterStore).addDnsToClusterEntry(
            _dns,
            address(msg.sender),
            _ipAddress,
            _whitelistedIps
        );
        return true;
    }

    /*
     * @title Staker could withdraw there staked stack tokens
     * @param Amount of stack tokens to unstake
     * @return True if successfully invoked
     */
    function withdraw(uint256 _amount) public returns (bool) {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount >= _amount, "Insufficient amount to withdraw");

        (
            ,
            ,
            ,
            uint256 upvotes,
            uint256 downvotes,
            bool isDefaulter,

        ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(
            stake.dns
        );
        uint256 slash;
        if (isDefaulter == true) {
            slash = (downvotes / upvotes) * slashFactor;
        }
        uint256 actualWithdrawAmount;
        if (_amount > slash) {
            actualWithdrawAmount = _amount - slash;
        } else {
            actualWithdrawAmount = 0;
        }
        stake.lastWithdraw = block.timestamp;
        stake.amount = stake.amount - (actualWithdrawAmount + slash);
        if (stake.amount <= 0) {
            // Remove entry from metadata contract
            IDnsClusterMetadataStore(dnsClusterStore).removeDnsToClusterEntry(
                stake.dns
            );
        }
        stake.share = _calcStakedShare(stake.amount, msg.sender);
        slashCollected = slashCollected + slash;

        IERC20(stackToken).transfer(msg.sender, actualWithdrawAmount);
        return true;
    }

    /*
     * @title Non Defaulter Users could claim the slashed rewards that is accumulated from bad actors
     */
    function claimSlashedRewards() public {
        Stake storage stake = stakes[msg.sender];
        require(stake.stakedAt > 0, "Not a staker");
        require(
            (block.timestamp - stake.lastRewardsCollectedAt) > DAY,
            "Try again after 24 Hours"
        );
        (
            ,
            ,
            ,
            uint256 upvotes,
            ,
            bool isDefaulter,

        ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(
            stake.dns
        );
        require(
            !isDefaulter,
            "Stakers marked as defaulters are not eligible to claim the rewards"
        );
        uint256 stakedShare = getStakedShare();
        uint256 stakedShareRewards = stakedShare * rewardsPerShare;
        uint256 upvoteRewards = upvotes * rewardsPerUpvote;
        uint256 rewardFunds = stakedShareRewards + upvoteRewards;
        require(slashCollected >= rewardFunds, "Insufficient reward funds");
        slashCollected = slashCollected - (rewardFunds);
        stake.lastRewardsCollectedAt = block.timestamp;
        IERC20(stackToken).transfer(msg.sender, rewardFunds);

        emit SlashCollectedLog(msg.sender, rewardFunds, block.timestamp);
    }

    /*
     * @title Fetches the Invoker Staked share from the total pool
     * @return User's Share
     */
    function getStakedShare() public view returns (uint256) {
        Stake storage stake = stakes[msg.sender];
        return _calcStakedShare(stake.amount, msg.sender);
    }

    function _calcStakedShare(uint256 stakedAmount, address staker)
        internal
        view
        returns (uint256 share)
    {
        uint256 totalSupply = IERC20(stackToken).balanceOf(address(this));
        uint256 exponentialAmount = EXP * stakedAmount;
        share = exponentialAmount / totalSupply;
    }
}
