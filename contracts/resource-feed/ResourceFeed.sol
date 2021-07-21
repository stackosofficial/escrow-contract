pragma solidity ^0.6.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";

/// @title ResourceFeed is a Contract which is ownership functionality
/// @notice Used for maintaining state of StackOS Resource's components prices
contract ResourceFeed is Ownable {
    address public stackToken;
    address public USDToken;
    address public clusterMetadataStore;

    // votingWeightPerUtilisedFUnds;

    struct Resource {
        string name;
        uint256 dripRatePerUnit;
        uint256 votingWeightPerUnit;
    }

    mapping(bytes32 => mapping(string => Resource)) public resources;

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of USDT(basecurrency) deployed contract
     */
    constructor(address _stackToken, address _USDToken) public {
        stackToken = _stackToken;
        USDToken = _USDToken;
    }

    /*
     * @title Add a new resource component
     * @param name of the resource
     * @param Drip Rate for a single unit
     * @param Vote weightage of a single unit
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */

    function setclusterMetadataStore(address _clustermetadatastore)
        public
        onlyOwner
    {
        clusterMetadataStore = _clustermetadatastore;
    }

    // Added in Dollar value.
    function addResource(
        bytes32 clusterDns,
        string memory name,
        uint256 dripRatePerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        resource.name = name;
        resource.dripRatePerUnit = dripRatePerUnit;
        return true;
    }

    /*
     * @title Remove a resource from the list
     * @param name of the resource
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */
    function removeResource(bytes32 clusterDns, string memory name)
        public
        returns (bool)
    {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        delete resources[clusterDns][name];
        return true;
    }

    /*
     * @title Update resource's drip rate
     * @param name of the resource
     * @param New DripRate for the resource
     * @return True if successfully invoked
     */
    function setResourceDripRateUSDT(
        bytes32 clusterDns,
        string memory name,
        uint256 dripRatePerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        resource.dripRatePerUnit = dripRatePerUnit;
        return true;
    }

    /*
     * @title Fetches a Resource's Drip Rate
     * @param name of the resource
     * @return Resource Drip rate
     */
    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256)
    {
        Resource storage resource = resources[clusterDns][name];
        return resource.dripRatePerUnit;
    }

    /*
     * @title Update resource's voting weight
     * @param name of the resource
     * @param New voting weight for the resource
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */
    function setResourceVotingWeight(
        bytes32 clusterDns,
        string calldata name,
        uint256 votingWeightPerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        resource.votingWeightPerUnit = votingWeightPerUnit;
        return true;
    }

    /*
     * @title Fetches a Resource's voting weight
     * @param name of the resource
     * @return Resource voting weight
     */
    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        public
        view
        returns (uint256)
    {
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        return resource.votingWeightPerUnit;
    }
}
