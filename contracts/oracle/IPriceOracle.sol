pragma solidity ^0.6.12;

interface IPriceOracle {
    function update(address tokenA, address tokenB) external virtual;

    function usdtToSTACKOracle(uint256 amountIn)
        external
        view
        virtual
        returns (uint256);
}
