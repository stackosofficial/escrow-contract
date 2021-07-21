pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./BaseEscrow.sol";

contract DelegatedDepositEscrow is BaseEscrow {
    constructor(
        address _stackToken,
        address _resourceFeed,
        address _staking,
        address _dnsStore,
        IUniswapV2Factory _factory,
        IUniswapV2Router02 _router,
        address _dao,
        address _governance,
        address _weth,
        address _usdt,
        address _oracle
    )
        public
        BaseEscrow(
            _stackToken,
            _resourceFeed,
            _staking,
            _dnsStore,
            _factory,
            _router,
            _dao,
            _governance,
            _weth,
            _usdt,
            _oracle
        )
    {}

    // function updateResourcesByStackAmount(
    //     bytes32 clusterDns,
    //     uint256 resourceOneUnits, // cpuCoresUnits
    //     uint256 resourceTwoUnits, // diskSpaceUnits
    //     uint256 resourceThreeUnits, // bandwidthUnits
    //     uint256 resourceFourUnits, // memoryUnits
    //     uint256 resourceFiveUnits,
    //     uint256 resourceSixUnits,
    //     uint256 resourceSevenUnits,
    //     uint256 resourceEightUnits,
    //     uint256 depositAmount
    // ) public onlyOwner {
    //     Deposit storage deposit = deposits[msg.sender][clusterDns];
    //     require(deposit.lastTxTime == 0, "Not the first deposit");
    //     require(deposit.totalDeposit == 0, "Non zero amount already deposited");
    //     require(depositAmount > 0, "zero deposit amount");

    //     _createDepositInternal(
    //         clusterDns,
    //         resourceOneUnits,
    //         resourceTwoUnits,
    //         resourceThreeUnits,
    //         resourceFourUnits,
    //         resourceFiveUnits,
    //         resourceSixUnits,
    //         resourceSevenUnits,
    //         resourceEightUnits,
    //         depositAmount,
    //         msg.sender,
    //         true
    //     );
    // }

    // function updateResourcesFromStack(
    //     bytes32 clusterDns,
    //     uint256 resourceOneUnits, // cpuCoresUnits
    //     uint256 resourceTwoUnits, // diskSpaceUnits
    //     uint256 resourceThreeUnits, // bandwidthUnits
    //     uint256 resourceFourUnits, // memoryUnits
    //     uint256 resourceFiveUnits,
    //     uint256 resourceSixUnits,
    //     uint256 resourceSevenUnits,
    //     uint256 resourceEightUnits
    // ) public onlyOwner {
    //     uint256 depositAmount = getResourcesPriceInSTACK(
    //         clusterDns,
    //         resourceOneUnits,
    //         resourceTwoUnits,
    //         resourceThreeUnits,
    //         resourceFourUnits,
    //         resourceFiveUnits,
    //         resourceSixUnits,
    //         resourceSevenUnits,
    //         resourceEightUnits
    //     );
    //     Deposit storage deposit = deposits[msg.sender][clusterDns];
    //     if (deposit.lastTxTime > 0) {
    //         settleAccounts(msg.sender, clusterDns);
    //     }

    //     _createDepositInternal(
    //         clusterDns,
    //         resourceOneUnits,
    //         resourceTwoUnits,
    //         resourceThreeUnits,
    //         resourceFourUnits,
    //         resourceFiveUnits,
    //         resourceSixUnits,
    //         resourceSevenUnits,
    //         resourceEightUnits,
    //         depositAmount,
    //         msg.sender,
    //         true
    //     );
    // }

    // function getResourcesPriceInSTACK(
    //     bytes32 clusterDns,
    //     uint256 resourceOneUnits, // cpuCoresUnits
    //     uint256 resourceTwoUnits, // diskSpaceUnits
    //     uint256 resourceThreeUnits, // bandwidthUnits
    //     uint256 resourceFourUnits, // memoryUnits
    //     uint256 resourceFiveUnits,
    //     uint256 resourceSixUnits,
    //     uint256 resourceSevenUnits,
    //     uint256 resourceEightUnits
    // ) public view returns (uint256) {
    //     uint256 amountInUSDT = _calcResourceUnitsPriceUSDT(
    //         clusterDns,
    //         resourceVar[1],
    //         resourceOneUnits
    //     ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[2],
    //             resourceTwoUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[3],
    //             resourceThreeUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[4],
    //             resourceFourUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[5],
    //             resourceFiveUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[6],
    //             resourceSixUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[7],
    //             resourceSevenUnits
    //         ) +
    //         _calcResourceUnitsPriceUSDT(
    //             clusterDns,
    //             resourceVar[8],
    //             resourceEightUnits
    //         );

    //     uint256 amountInSTACK = usdtToSTACK(amountInUSDT);
    //     return amountInSTACK;
    // }

    // function getResourcesDripRateInUSDT(
    //     bytes32 clusterDns,
    //     uint256 resourceOneUnits, // cpuCoresUnits
    //     uint256 resourceTwoUnits, // diskSpaceUnits
    //     uint256 resourceThreeUnits, // bandwidthUnits
    //     uint256 resourceFourUnits, // memoryUnits
    //     uint256 resourceFiveUnits,
    //     uint256 resourceSixUnits,
    //     uint256 resourceSevenUnits,
    //     uint256 resourceEightUnits
    // ) public view returns (uint256) {
    //     uint256 amountInUSDT = _calcResourceUnitsDripRateUSDT(
    //         clusterDns,
    //         resourceVar[1],
    //         resourceOneUnits
    //     ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[2],
    //             resourceTwoUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[3],
    //             resourceThreeUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[4],
    //             resourceFourUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[5],
    //             resourceFiveUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[6],
    //             resourceSixUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[7],
    //             resourceSevenUnits
    //         ) +
    //         _calcResourceUnitsDripRateUSDT(
    //             clusterDns,
    //             resourceVar[8],
    //             resourceEightUnits
    //         );
    //     return amountInUSDT;
    // }

    // function rechargeAccount(
    //     uint256 amount,
    //     address depositer,
    //     bytes32 clusterDns
    // ) public {
    //     _rechargeAccountInternal(amount, depositer, clusterDns, true);
    // }

    // function withdrawFundsPartial(
    //     uint256 amount,
    //     address depositer,
    //     bytes32 clusterDns
    // ) public onlyOwner {
    //     _withdrawFundsPartialInternal(amount, depositer, clusterDns);
    // }
}
