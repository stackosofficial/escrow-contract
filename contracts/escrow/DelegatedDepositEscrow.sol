pragma solidity ^0.6.12;

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

    function updateResourcesByStackAmount(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits,
        uint256 depositAmount,
        address depositer
    ) public onlyOwner {
        Deposit storage deposit = deposits[depositer][clusterDns];
        require(deposit.lastTxTime == 0, "Not the first deposit");
        require(deposit.totalDeposit == 0, "Non zero amount already deposited");
        require(depositAmount > 0, "zero deposit amount");

        _createDepositInternal(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwidthUnits,
            memoryUnits,
            depositAmount,
            depositer
        );
    }

    function updateResourcesFromStack(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits,
        address depositer
    ) public onlyOwner {
        uint256 depositAmount = getResourcesPrice(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwidthUnits,
            memoryUnits
        );
        Deposit storage deposit = deposits[depositer][clusterDns];
        if (deposit.lastTxTime > 0) {
            settleAccounts(msg.sender, clusterDns);
        }

        _createDepositInternal(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwidthUnits,
            memoryUnits,
            depositAmount,
            depositer
        );
    }

    function getResourcesPrice(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256) {
        uint256 amountInStack = _calcResourceUnitsPriceUSDT(
            clusterDns,
            "cpu",
            cpuCoresUnits
        ) +
            _calcResourceUnitsPriceUSDT(clusterDns, "memory", memoryUnits) +
            _calcResourceUnitsPriceUSDT(clusterDns, "disk", diskSpaceUnits) +
            _calcResourceUnitsPriceUSDT(
                clusterDns,
                "bandwidth",
                bandwidthUnits
            );

        return amountInStack;
    }

    function getResourcesDripRate(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256) {
        uint256 amountInStack = _calcResourceUnitsDripRateUSDT(
            clusterDns,
            "cpu",
            cpuCoresUnits
        ) +
            _calcResourceUnitsDripRateUSDT(clusterDns, "memory", memoryUnits) +
            _calcResourceUnitsDripRateUSDT(clusterDns, "disk", diskSpaceUnits) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                "bandwidth",
                bandwidthUnits
            );

        return amountInStack;
    }

    function rechargeAccount(
        uint256 amount,
        address depositer,
        bytes32 clusterDns
    ) public {
        _rechargeAccountInternal(amount, depositer, clusterDns);
    }

    // function withdrawFundsPartial(
    //     uint256 amount,
    //     address depositer,
    //     bytes32 clusterDns
    // ) public onlyOwner {
    //     _withdrawFundsPartialInternal(amount, depositer, clusterDns);
    // }
}
