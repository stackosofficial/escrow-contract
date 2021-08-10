pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "../escrow/EscrowLib.sol";

interface IResourceFeed {

    function getResourceDripRateUSDT(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceVotingWeight(bytes32 clusterDns, string calldata name)
        external
        view
        returns (uint256);

    function getResourceMaxCapacity(bytes32 clusterDns)
        external
        returns (EscrowLib.ResourceUnits memory);
}
