pragma solidity ^0.6.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

import "../library/SafeMath.sol";
import "../library/UniswapV2Library.sol";
import "../library/UniswapV2OracleLibrary.sol";
import "./IPriceOracle.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// fixed window oracle that recomputes the average price for the entire period once every period
// note that the price average is only guaranteed to be over at least 1 period, but may be over a longer period
contract StackOracle {
    using FixedPoint for *;

    uint256 public constant PERIOD = 24 hours;

    IUniswapV2Pair immutable pairWETHSTACK;
    IUniswapV2Pair immutable pairWETHUSDT;

    uint256 public price0CumulativeLastETHSTACK;
    uint256 public price1CumulativeLastETHSTACK;

    uint256 public price0CumulativeLastWETHUSDT;
    uint256 public price1CumulativeLastWETHUSDT;

    FixedPoint.uq112x112 public price0AverageWETHSTACK;
    FixedPoint.uq112x112 public price1AverageWETHSTACK;

    FixedPoint.uq112x112 public price0AverageWETHUSDT;
    FixedPoint.uq112x112 public price1AverageWETHUSDT;

    uint32 public blockTimestampLast;

    address public immutable WETH;
    uint256 public immutable USDT;
    uint256 public immutable STACK;

    constructor(
        address lpstack,
        address lpusdt,
        address weth
    ) public {
        IUniswapV2Pair _pairWETHUSDT = IUniswapV2Pair(lpusdt);
        pairWETHUSDT = _pairWETHUSDT;
        WETH = weth;
        uint256 setUSDT;
        uint256 setSTACK;
        if (_pairWETHUSDT.token0() != weth) {
            setUSDT = 0;
        } else {
            setUSDT = 1;
        }
        USDT = setUSDT;

        price0CumulativeLastWETHUSDT = _pairWETHUSDT.price0CumulativeLast(); // fetch the current accumulated price value
        price1CumulativeLastWETHUSDT = _pairWETHUSDT.price1CumulativeLast(); // fetch the current accumulated price value

        uint112 reserve0WETHUSDT;
        uint112 reserve1WETHUSDT;

        (reserve0WETHUSDT, reserve1WETHUSDT, blockTimestampLast) = _pairWETHUSDT
            .getReserves();

        // ETH/STACK
        IUniswapV2Pair _pairWETHSTACK = IUniswapV2Pair(lpstack);
        pairWETHSTACK = _pairWETHSTACK;

        if (_pairWETHSTACK.token0() != weth) {
            setSTACK = 0;
        } else {
            setSTACK = 1;
        }
        STACK = setSTACK;

        price0CumulativeLastETHSTACK = _pairWETHSTACK.price0CumulativeLast(); // fetch the current accumulated price value
        price1CumulativeLastETHSTACK = _pairWETHSTACK.price1CumulativeLast();

        uint112 reserve0WETHSTACK;
        uint112 reserve1WETHSTACK;
        (
            reserve0WETHSTACK,
            reserve1WETHSTACK,
            blockTimestampLast
        ) = _pairWETHSTACK.getReserves();
    }

    function update() external {
        // ETH/STACK

        (
            uint256 price0CumulativeWETHSTACK,
            uint256 price1CumulativeWETHSTACK,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(
                address(pairWETHSTACK)
            );
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired

        // ETH/STACK

        price0AverageWETHSTACK = FixedPoint.uq112x112(
            uint224(
                (price0CumulativeWETHSTACK - price0CumulativeLastETHSTACK) /
                    timeElapsed
            )
        );
        price1AverageWETHSTACK = FixedPoint.uq112x112(
            uint224(
                (price1CumulativeWETHSTACK - price1CumulativeLastETHSTACK) /
                    timeElapsed
            )
        );
        // ETH/STACK
        price0CumulativeLastETHSTACK = price0CumulativeWETHSTACK;
        price1CumulativeLastETHSTACK = price1CumulativeWETHSTACK;
        // ensure that at least one full period has passed since the last update
        require(
            timeElapsed >= PERIOD,
            "ExampleOracleSimple: PERIOD_NOT_ELAPSED"
        );

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed

        // ETH / USDT

        (
            uint256 price0CumulativeWETHUSDT,
            uint256 price1CumulativeWETHUSDT,

        ) = UniswapV2OracleLibrary.currentCumulativePrices(
                address(pairWETHUSDT)
            );
        // ETH / USDT
        price0AverageWETHUSDT = FixedPoint.uq112x112(
            uint224(
                (price0CumulativeWETHUSDT - price0CumulativeLastWETHUSDT) /
                    timeElapsed
            )
        );
        price1AverageWETHUSDT = FixedPoint.uq112x112(
            uint224(
                (price1CumulativeWETHUSDT - price1CumulativeLastWETHUSDT) /
                    timeElapsed
            )
        );

        // ETH / USDT
        price0CumulativeLastWETHUSDT = price0CumulativeWETHUSDT;
        price1CumulativeLastWETHUSDT = price1CumulativeWETHUSDT;

        blockTimestampLast = blockTimestamp;
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function usdtToSTACKOracle(uint256 amountIn)
        external
        view
        returns (uint256 amountOut)
    {
        uint256 wethAmount;
        if (USDT == 0)
            wethAmount = price0AverageWETHUSDT.mul(amountIn).decode144();
        else wethAmount = price1AverageWETHUSDT.mul(amountIn).decode144();

        if (STACK == 0)
            amountOut = price1AverageWETHSTACK.mul(wethAmount).decode144();
        else amountOut = price0AverageWETHSTACK.mul(wethAmount).decode144();
    }
}
