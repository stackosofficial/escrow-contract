pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";
import "../escrow/IEscrow.sol";
import "../escrow/EscrowLib.sol";

/// @title ResourceFeed is a Contract which is ownership functionality
/// @notice Used for maintaining state of StackOS Resource's components prices
contract ResourceFeed is Ownable {
    address public stackToken;
    address public clusterMetadataStore;
    address public escrowAddress;

    // votingWeightPerUtilisedFUnds;

    struct Resource {
        string name;
        uint256 dripRatePerUnit;
        uint256 votingWeightPerUnit;
    }

    mapping(bytes32 => mapping(string => Resource)) public resources;
    mapping(bytes32 => EscrowLib.ResourceUnits) public resourcesMaxPerDNS;

    function setResourceMaxCapacity(
        bytes32 clusterDns,
        EscrowLib.ResourceUnits memory maxUnits
    ) public {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
            .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        resourcesMaxPerDNS[clusterDns] = maxUnits;
    }

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        view
        returns (EscrowLib.ResourceUnits memory)
    {
        return resourcesMaxPerDNS[clusterDns];
    }

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     */
    constructor(address _stackToken) public {
        stackToken = _stackToken;
    }

    /*
     * @title Add a new resource component
     * @param name of the resource
     * @param Drip Rate for a single unit
     * @param Vote weightage of a single unit
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */

    function setAddressSetting(address _clustermetadatastore, address _escrow)
        public
        onlyOwner
    {
        clusterMetadataStore = _clustermetadatastore;
        escrowAddress = _escrow;
    }

    // Added in Dollar value.
    function addResource(
        bytes32 clusterDns,
        uint8 resourceID,
        uint256 dripRatePerUnit
    ) public returns (bool) {
        address clusterOwner = IDnsClusterMetadataStore(clusterMetadataStore)
            .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        require(
            bytes(IEscrow(escrowAddress).getResouceVar(resourceID)).length != 0
        );
        Resource storage resource = resources[clusterDns][
            IEscrow(escrowAddress).getResouceVar(resourceID)
        ];
        resource.name = IEscrow(escrowAddress).getResouceVar(resourceID);
        resource.dripRatePerUnit = dripRatePerUnit;
        return true;
    }

    /*
     * @title Remove a resource from the list
     * @param name of the resource
     * @return True if successfully invoked
     * @dev Could only be invoked by the contract owner
     */
    function removeResource(bytes32 clusterDns, uint8 resourceID)
        public
        returns (bool)
    {
        require(
            bytes(IEscrow(escrowAddress).getResouceVar(resourceID)).length != 0
        );
        require(
            IDnsClusterMetadataStore(clusterMetadataStore).getClusterOwner(
                clusterDns
            ) == msg.sender,
            "Not the cluster owner!"
        );
        delete resources[clusterDns][
            IEscrow(escrowAddress).getResouceVar(resourceID)
        ];
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
     * @dev Could only be invoked by the contract owner
     */
    function setResourceVotingWeight(
        bytes32 clusterDns,
        string calldata name,
        uint256 votingWeightPerUnit
    ) public onlyOwner {
        Resource storage resource = resources[clusterDns][name];
        require(
            keccak256(abi.encodePacked(resource.name)) ==
                keccak256(abi.encodePacked(name)),
            "Resource not added."
        );
        resource.votingWeightPerUnit = votingWeightPerUnit;
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
        if (
            keccak256(abi.encodePacked(resource.name)) ==
            keccak256(abi.encodePacked(name))
        ) return resource.votingWeightPerUnit;
        else return 0;
    }

    /*
     * @dev - converts string to bytes32
     * @param string
     * @return bytes32 - converted bytes
     */
    function stringToBytes32(string memory source)
        public
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /*
     * @dev - converts bytes32 to string
     * @param bytes32
     * @return string - converted string
     */
    function bytes32ToString(bytes32 x)
        public
        pure
        returns (string memory, uint256)
    {
        bytes memory bytesString = new bytes(32);
        uint256 charCount = 0;
        for (uint256 j = 0; j < 32; j++) {
            bytes1 char = bytes1(bytes32(uint256(x) * 2**(8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint256 j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return (string(bytesStringTrimmed), charCount);
    }
}
