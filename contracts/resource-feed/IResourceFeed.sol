pragma solidity ^0.6.12;

interface IResourceFeed {
    function getResourcePrice(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceDripRate(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function USDToken() external view returns (address);
}
