pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "../escrow/EscrowLib.sol";

interface IEscrow {
    function getDeposits(address depositer, bytes32 clusterDns)
        external
        returns (EscrowLib.Deposit memory);

    function getResouceVar(uint16 _id) external returns (string memory);
}
