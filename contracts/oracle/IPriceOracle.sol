pragma solidity ^0.6.12;

interface IPriceOracle {
    function update(address tokenA, address tokenB) external virtual;

    function consult(
        address tokenIn,
        uint256 amountIn,
        address tokenOut
    ) external view virtual returns (uint256);
}
