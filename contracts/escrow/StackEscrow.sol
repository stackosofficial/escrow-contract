pragma solidity ^0.6.12;

import "./BaseEscrow.sol";

// /// @title StackEscrow is derived from the BaseEscrow Contract
// /// @notice Major contract responsible for user to purchase or update StackOS's resources from ETH & Stack Token
contract StackEscrow is BaseEscrow {
    //     // Public Functions

    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of ResourceFeed deployed contract
     * @param Address of StackOS Controller
     * @param Address of Staking deployed contract
     * @param Address of DnsClusterMetadataStore deployed contract
     * @param Platform Fees
     * @param Factory Contract of DEX
     * @param Router Contract of DEX
     * @param WETH Contract Address
     */
    constructor(
        address _stackToken,
        address _resourceFeed,
        address _staking,
        address _dnsStore,
        IUniswapV2Factory _factory,
        IUniswapV2Router02 _router,
        address _dao,
        address _gov,
        address _weth,
        address _usdt
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
            _gov,
            _weth,
            _usdt
        )
    {
        stackToken = _stackToken;
    }

    /*
     * @title Purchase the resources from STACK token
     * @param DNS Cluster
     * @param Number of CPU's core units to purchase
     * @param Number of Disk space units to purchase
     * @param Number of Bandwidth units to purchase
     * @param Number of Memory units to purchase
     * @param Deposit Amount in stack token
     * @dev User should only invoke the function when performing initial deposit
     */
    function updateResourcesByStackAmount(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits,
        uint256 depositAmount
    ) public {
        Deposit storage deposit = deposits[msg.sender][clusterDns];
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
            msg.sender
        );
    }

    /*
     * @title Update the user's resources from STACK token
     * @param DNS Cluster
     * @param Number of CPU's core units to purchase
     * @param Number of Disk space units to purchase
     * @param Number of Bandwidth units to purchase
     * @param Number of Memory units to purchase
     * @dev User should have the Amount of Stack Token in his wallet that will be used for the resources he/she is accesseing
     */
    function updateResourcesFromStack(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public {
        uint256 depositAmount = getResourcesPrice(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwidthUnits,
            memoryUnits
        );
        {
            Deposit storage deposit = deposits[msg.sender][clusterDns];
            if (deposit.lastTxTime > 0) {
                settleAccounts(msg.sender, clusterDns);
            }
        }

        _createDepositInternal(
            clusterDns,
            cpuCoresUnits,
            diskSpaceUnits,
            bandwidthUnits,
            memoryUnits,
            depositAmount,
            msg.sender
        );
    }

    function rebateAccount(
        uint256 amount,
        address account,
        bytes32 clusterDns
    ) public {
        Deposit storage deposit = deposits[account][clusterDns];
        deposit.totalDeposit = deposit.totalDeposit + amount;
        // Charge the person who is doing the rebate.
        _pullStackTokens(amount);
    }

    /*
     * @title Fetches the cummulative price of Resources in STACK
     * @param Number of CPU's core units
     * @param Number of Disk space units
     * @param Number of Bandwidth units
     * @param Number of Memory units
     * @return Total resources price measured in Stack Token
     */
    function getResourcesPrice(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256) {
        uint256 amountInStack = _calcResourceUnitsPrice(
            clusterDns,
            "cpu",
            cpuCoresUnits
        ) +
            _calcResourceUnitsPrice(clusterDns, "memory", memoryUnits) +
            _calcResourceUnitsPrice(clusterDns, "disk", diskSpaceUnits) +
            _calcResourceUnitsPrice(clusterDns, "bandwidth", bandwidthUnits);

        // Introduce a to Stack converter here.
        // Right now everything unit prices are in USD.

        return amountInStack;
    }

    /*
     * @title Fetches the cummulative price of Resources in ETH
     * @param Number of CPU's core units
     * @param Number of Disk space units
     * @param Number of Bandwidth units
     * @param Number of Memory units
     * @return Total resources price measured in Ethereum
     */
    function getResourcesPriceInSTACK(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256) {
        uint256 amountInUsdT = _calcResourceUnitsPrice(
            clusterDns,
            "cpu",
            cpuCoresUnits
        ) +
            _calcResourceUnitsPrice(clusterDns, "memory", memoryUnits) +
            _calcResourceUnitsPrice(clusterDns, "disk", diskSpaceUnits) +
            _calcResourceUnitsPrice(clusterDns, "bandwidth", bandwidthUnits);
        uint256 amountInSTACK = usdtToSTACK(amountInUsdT);
        return amountInSTACK;
    }

    /*
     * @title Fetches the cummulative dripRate of Resources
     * @param Number of CPU's core units
     * @param Number of Disk space units
     * @param Number of Bandwidth units
     * @param Number of Memory units
     * @return Total resources drip rate measured in Stack Token
     */
    function getResourcesDripRate(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) public view returns (uint256) {
        uint256 amountInUSD = _calcResourceUnitsDripRate(
            clusterDns,
            "cpu",
            cpuCoresUnits
        ) +
            _calcResourceUnitsDripRate(clusterDns, "memory", memoryUnits) +
            _calcResourceUnitsDripRate(clusterDns, "disk", diskSpaceUnits) +
            _calcResourceUnitsDripRate(clusterDns, "bandwidth", bandwidthUnits);
        return amountInUSD;
    }

    /*
     * @title TopUp the user's Account with input Amount
     * @param Amount of Stack Token to TopUp the account with
     */
    function rechargeAccount(uint256 amount, bytes32 clusterDns) public {
        _rechargeAccountInternal(amount, msg.sender, clusterDns);
    }

    /*
    //  * @title Withdraw user total deposited Funds & settles his pending balances
    //  */
    function withdrawFunds(bytes32 clusterDns) public {
        _settleBalances(msg.sender, clusterDns);
    }

    function setWithdrawTokenPortion(address token, uint256 percent) public {
        require(percent <= 10000, "Has to be below 10000");
        WithdrawSetting storage withdrawsetup = withdrawsettings[msg.sender];
        withdrawsetup.token = token;
        withdrawsetup.percent = percent;
    }

    // /*
    //  * @title Withdraw user deposited Funds partially
    //  * @param Amount of Stack Token user wants to withdraw
    //  */
    // function withdrawFundsPartial(uint256 amount, bytes32 clusterDns) public {
    //     _withdrawFundsPartialInternal(amount, msg.sender, clusterDns);
    // }
}
