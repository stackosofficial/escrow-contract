pragma solidity ^0.6.12;

interface IEscrow {
    function deposits(address depositer)
        external
        returns (
            bytes32,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );
}
