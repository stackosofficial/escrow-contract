pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IResourceFeed {
    struct ResourceCapacity {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
    }

    function getResourcePriceUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function USDToken() external view returns (address);

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        returns (ResourceCapacity memory);
}
