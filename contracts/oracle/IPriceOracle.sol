pragma solidity ^0.6.12;

interface IPriceOracle {
    function update() external;

    function usdtToSTACKOracle(uint256 amountIn)
        external
        view
        returns (uint256);
}
