pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IDnsClusterMetadataStore {
    function dnsToClusterMetadata(bytes32)
        external
        returns (
            address,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            uint256,
            bool,
            string memory,
            bool
        );

    function addDnsToClusterEntry(
        bytes32 _dns,
        address _clusterOwner,
        string memory ipAddress,
        string memory _whitelistedIps,
        string memory _clusterType,
        bool _isPrivate
    ) external;

    function removeDnsToClusterEntry(bytes32 _dns) external;

    function upvoteCluster(bytes32 _dns) external;

    function downvoteCluster(bytes32 _dns) external;

    function markClusterAsDefaulter(bytes32 _dns) external;

    function getClusterOwner(bytes32 clusterDns) external returns (address);
}
