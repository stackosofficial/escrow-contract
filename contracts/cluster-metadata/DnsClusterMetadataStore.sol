pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../escrow/IEscrow.sol";
import "../resource-feed/IResourceFeed.sol";
import "../escrow/EscrowLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title DnsClusterMetadataStore is a Contract which is ownership functionality
/// @notice Used for maintaining state of Clusters & there voting
contract DnsClusterMetadataStore is Ownable {
    using SafeMath for uint256;
    address public stakingContract;
    address public escrowAddress;
    IResourceFeed public resourceFeed;

    struct ClusterMetadata {
        address clusterOwner;
        string ipAddress;
        string whitelistedIps;
        uint256 upvotes;
        uint256 downvotes;
        bool isDefaulter;
        uint256 qualityFactor;
        bool active;
        string clusterType;
        bool isPrivate;
    }

    mapping(bytes32 => mapping(address => uint256)) public clusterUpvotes;
    mapping(bytes32 => mapping(address => uint256)) public clusterDownvotes;
    mapping(bytes32 => ClusterMetadata) public dnsToClusterMetadata;

    /*
     * @dev - constructor (being called at contract deployment)
     * @param resourceFeed - deployed Address of Resource Feed Contract
     */
    constructor(IResourceFeed _resourceFeed) public {
        resourceFeed = _resourceFeed;
    }

    modifier onlyStakingContract() {
        require(
            msg.sender == stakingContract,
            "Invalid Caller: Not a staking contract"
        );
        _;
    }

    /*
     * @title - Modifies the staking contract Address
     * @param deployed Address of Staking Contract
     * @param deployed Address of Escrow Contract
     * @dev Could only be called by the Owner of contract
     */
    function setAddressSetting(address _stakingContract, address _escrow)
        public
        onlyOwner
    {
        stakingContract = _stakingContract;
        escrowAddress = _escrow;
    }

    /*
     * @title creates new dns entry
     * @param dns name
     * @param cluster owner address
     * @param IPAddress of dns
     * @param whitelisted IP
     * @param cluster type
     * @param isPrivate
     * @dev Could only be invoked by the staking contract
     */
    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory _ipAddress,
        string memory _whitelistedIps,
        string memory _clusterType,
        bool _isPrivate
    ) public onlyStakingContract {
        ClusterMetadata memory clusterMetadata = dnsToClusterMetadata[_dns];
        require(clusterMetadata.clusterOwner == address(0));
        ClusterMetadata memory metadata = ClusterMetadata(
            _clusterOwner,
            _ipAddress,
            _whitelistedIps,
            0,
            0,
            false,
            100,
            true,
            _clusterType,
            _isPrivate
        );

        dnsToClusterMetadata[_dns] = metadata;
    }

    function changeClusterStatus(bytes32 _dns, bool _status) public {
        require(dnsToClusterMetadata[_dns].clusterOwner == msg.sender);
        dnsToClusterMetadata[_dns].active = _status;
    }

    /*
     * @title removes the pre added dns entry
     * @param dns name
     * @dev Could only be invoked by the staking contract
     */
    function removeDnsToClusterEntry(bytes32 _dns) public onlyStakingContract {
        delete dnsToClusterMetadata[_dns];
    }

    /*
     * @title upvote a particular cluster , depicting a good service
     * @param dns name of a cluster
     */
    function upvoteCluster(bytes32 _dns) public {
        // check here if _dns = deposit.clusterDns
        EscrowLib.Deposit memory deposit = IEscrow(escrowAddress).getDeposits(
            msg.sender,
            _dns
        );
        // make this a function of utilised funds
        uint256 votingCapacity = getTotalVotes(
            deposit.resourceOneUnits,
            deposit.resourceTwoUnits,
            deposit.resourceThreeUnits,
            deposit.resourceFourUnits, // memoryUnits
            deposit.resourceFiveUnits,
            deposit.resourceSixUnits,
            deposit.resourceSevenUnits,
            deposit.resourceEightUnits,
            _dns
        );
        require(
            clusterUpvotes[_dns][msg.sender] <= votingCapacity,
            "Already upvoted"
        );

        if (
            clusterDownvotes[_dns][msg.sender] > 0 &&
            dnsToClusterMetadata[_dns].downvotes > 0
        ) {
            clusterDownvotes[_dns][msg.sender] -= 1;
            dnsToClusterMetadata[_dns].downvotes -= 1;
        }

        clusterUpvotes[_dns][msg.sender] += 1;
        dnsToClusterMetadata[_dns].upvotes += 1;
    }

    /*
     * @title downvote a particular cluster , depicting a bad service
     * @param dns name of the cluster
     */
    function downvoteCluster(bytes32 _dns) public {
        EscrowLib.Deposit memory deposit = IEscrow(escrowAddress).getDeposits(
            msg.sender,
            _dns
        );

        uint256 votingCapacity = getTotalVotes(
            deposit.resourceOneUnits,
            deposit.resourceTwoUnits,
            deposit.resourceThreeUnits,
            deposit.resourceFourUnits, // memoryUnits
            deposit.resourceFiveUnits,
            deposit.resourceSixUnits,
            deposit.resourceSevenUnits,
            deposit.resourceEightUnits,
            _dns
        );
        require(
            clusterDownvotes[_dns][msg.sender] <= votingCapacity,
            "Already downVoted"
        );

        if (
            clusterUpvotes[_dns][msg.sender] > 0 &&
            dnsToClusterMetadata[_dns].upvotes > 0
        ) {
            clusterUpvotes[_dns][msg.sender] -= 1;
            dnsToClusterMetadata[_dns].upvotes -= 1;
        }
        clusterDownvotes[_dns][msg.sender] += 1;
        dnsToClusterMetadata[_dns].downvotes += 1;
    }

    /*
     * @title Make a cluster defaulter
     * @param dns name
     * @dev Could only be invoked by the contract owner
     */
    function markClusterAsDefaulter(bytes32 _dns) public onlyOwner {
        require(
            dnsToClusterMetadata[_dns].clusterOwner != address(0),
            "Cluster not found"
        );
        dnsToClusterMetadata[_dns].isDefaulter = true;
    }

    function _calculateVotesPerResource(
        bytes32 clusterDns,
        string memory name,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        return
            resourceUnits
                .mul(resourceFeed.getResourceVotingWeight(clusterDns, name))
                .div(10**18);
    }

    /*
     * @title Fetches total number of votes based on the resources

     * @return number of votes
     */
    function getTotalVotes(
        uint256 resourceOneUnits, // cpuCoresUnits
        uint256 resourceTwoUnits, // diskSpaceUnits
        uint256 resourceThreeUnits, // bandwidthUnits
        uint256 resourceFourUnits, // memoryUnits
        uint256 resourceFiveUnits,
        uint256 resourceSixUnits,
        uint256 resourceSevenUnits,
        uint256 resourceEightUnits,
        bytes32 clusterDns
    ) public returns (uint256 votes) {
        votes =
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(1),
                resourceOneUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(2),
                resourceTwoUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(3),
                resourceThreeUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(4),
                resourceFourUnits
            );
        votes =
            votes +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(5),
                resourceFiveUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(6),
                resourceSixUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(7),
                resourceSevenUnits
            ) +
            _calculateVotesPerResource(
                clusterDns,
                IEscrow(escrowAddress).getResouceVar(8),
                resourceEightUnits
            );
    }

    function getClusterOwner(bytes32 clusterDns) public view returns (address) {
        return dnsToClusterMetadata[clusterDns].clusterOwner;
    }
}
