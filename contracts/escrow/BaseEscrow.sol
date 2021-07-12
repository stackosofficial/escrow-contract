pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./EscrowStorage.sol";
import "../cluster-metadata/IDnsClusterMetadataStore.sol";
import "../resource-feed/IResourceFeed.sol";
import "./uniswap/IUniswapV2Pair.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./uniswap/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/// @title BaseEscrow is parent contract of Stack Escrow
/// @notice Serves as base layer contract responsible for all major tasks
contract BaseEscrow is Ownable, EscrowStorage {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event WITHDRAW(
        address accountOwner,
        uint256 amountDeposited,
        uint256 amountWithdrawn,
        uint256 depositedAt
    );

    event DEPOSIT(
        bytes32 clusterDns,
        address indexed owner,
        uint256 totalDeposit,
        uint256 lastTxTime,
        uint256 indexed dripRate
    );

    /*
     * @dev - constructor (being called internally at Stack Escrow contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of ResourceFeed deployed contract
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
    ) public {
        stackToken = _stackToken;
        resourceFeed = _resourceFeed;
        staking = _staking;
        dnsStore = _dnsStore;
        factory = _factory;
        router = _router;
        weth = _weth;
        dao = _dao;
        gov = _gov;
        usdt = _usdt;
    }

    /*
     * @title Update the Platform Fees
     * @param Updated Platform Fees
     * @dev Could only be invoked by the contract owner
     */
    function setVariableFees(uint256 _govFee, uint256 _daoFee)
        public
        onlyOwner
    {
        daoFee = _daoFee;
        govFee = _govFee;
    }

    function setFixedFees(
        string memory allocatedFor,
        uint256 _cpuFee,
        uint256 _diskFee,
        uint256 _bandwidthFee,
        uint256 _memoryFee
    ) public onlyOwner {
        ResourceFees storage resourcefees = fixedResourceFee[allocatedFor];
        resourcefees.cpuFee = _cpuFee;
        resourcefees.diskFee = _diskFee;
        resourcefees.bandwidthFee = _bandwidthFee;
        resourcefees.memoryFee = _memoryFee;
    }

    function setFeeAddress(address _daoAddress, address _govAddress)
        public
        onlyOwner
    {
        dao = _daoAddress;
        gov = _govAddress;
    }

    /*
     * @title Withdraw a depositer funds
     * @param Depositer Address
     * @dev Could only be invoked by the contract owner
     */
    // function withDrawFundsAdmin(address depositer, uint256 node)
    //     public
    //     onlyOwner
    // {
    //     _settleBalances(depositer, node);
    // }

    /*
     * @title Settle Depositer Account
     * @param Depositer Address
     */
    function settleAccounts(address depositer, bytes32 clusterDns) public {
        uint256 currentTime = block.timestamp;
        Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 elapsedTime = currentTime - deposit.lastTxTime;
        // Set the current time as the lastTxTime.
        deposit.lastTxTime = currentTime;
        // need to reset time after fuction is triggered.

        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor
        ) = IDnsClusterMetadataStore(IDnsClusterMetadataStore(dnsStore))
        .dnsToClusterMetadata(clusterDns);

        // Convert utilised funds to STACK value.
        uint256 utilisedFunds = elapsedTime * deposit.totalDripRatePerSecond;
        utilisedFunds = usdtToSTACK(utilisedFunds);
        // Add fees to utilised funds.

        (uint256 fixedDaoFee, uint256 fixedGovFee) = _AddFixedFees(
            utilisedFunds,
            elapsedTime,
            deposit.cpuCoresUnits,
            deposit.diskSpaceUnits,
            deposit.bandwidthUnits,
            deposit.memoryUnits
        );

        utilisedFunds = utilisedFunds + fixedDaoFee + fixedGovFee;

        if (utilisedFunds >= deposit.totalDeposit) {
            utilisedFunds = deposit.totalDeposit;
            delete deposits[depositer][clusterDns];
        } else {
            deposit.totalDeposit = deposit.totalDeposit - utilisedFunds;
        }

        utilisedFunds = utilisedFunds - (fixedDaoFee + fixedGovFee);

        _withdraw(
            utilisedFunds,
            0,
            depositer,
            clusterOwner,
            clusterDns,
            qualityFactor
        );
    }

    function _AddFixedFees(
        uint256 utilisedFunds,
        uint256 timeelapsed,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) internal returns (uint256, uint256) {
        ResourceFees storage govFixedFees = fixedResourceFee["gov"];
        ResourceFees storage daoFixedFees = fixedResourceFee["dao"];
        uint256 daoFees;
        uint256 govFees;

        if (cpuCoresUnits > 0) {
            govFees =
                govFees +
                (cpuCoresUnits * govFixedFees.cpuFee * timeelapsed);
            daoFees =
                daoFees +
                (cpuCoresUnits * daoFixedFees.cpuFee * timeelapsed);
        }
        if (diskSpaceUnits > 0) {
            govFees =
                govFees +
                (cpuCoresUnits * govFixedFees.diskFee * timeelapsed);
            daoFees =
                daoFees +
                (cpuCoresUnits * daoFixedFees.diskFee * timeelapsed);
        }
        if (bandwidthUnits > 0) {
            govFees =
                govFees +
                (cpuCoresUnits * govFixedFees.bandwidthFee * timeelapsed);
            daoFees =
                daoFees +
                (cpuCoresUnits * daoFixedFees.bandwidthFee * timeelapsed);
        }
        if (memoryUnits > 0) {
            govFees =
                govFees +
                (cpuCoresUnits * govFixedFees.memoryFee * timeelapsed);
            daoFees =
                daoFees +
                (cpuCoresUnits * daoFixedFees.memoryFee * timeelapsed);
        }
        (uint256 variableDaoFee, uint256 variableGovFee) = _AddVariablesFees(
            utilisedFunds
        );
        daoFees = daoFees + variableDaoFee;
        govFees = govFees + variableGovFee;
        if (govFees > 0) IERC20(stackToken).transfer(gov, govFees);
        if (daoFees > 0) IERC20(stackToken).transfer(dao, daoFees);
        return (daoFees, govFees);
    }

    function _AddVariablesFees(uint256 utilisedFunds)
        internal
        view
        returns (uint256, uint256)
    {
        // Settle Dao and Gov
        uint256 forDao = (daoFee * (10**18) * utilisedFunds) / 10000 / (10**18);
        uint256 forGov = (govFee * (10**18) * utilisedFunds) / 10000 / (10**18);

        return (forDao, forGov);
    }

    function _createDepositInternal(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits,
        uint256 depositAmount,
        address depositer
    ) internal {
        Deposit storage deposit = deposits[depositer][clusterDns];

        deposit.lastTxTime = block.timestamp;
        deposit.cpuCoresUnits = cpuCoresUnits;
        deposit.diskSpaceUnits = diskSpaceUnits;
        deposit.bandwidthUnits = bandwidthUnits;
        deposit.memoryUnits = memoryUnits;

        deposit.totalDripRatePerSecond =
            _calcResourceUnitsDripRate(
                clusterDns,
                "cpu",
                deposit.cpuCoresUnits
            ) +
            _calcResourceUnitsDripRate(
                clusterDns,
                "memory",
                deposit.memoryUnits
            ) +
            _calcResourceUnitsDripRate(
                clusterDns,
                "disk",
                deposit.diskSpaceUnits
            ) +
            _calcResourceUnitsDripRate(
                clusterDns,
                "bandwidth",
                deposit.bandwidthUnits
            );

        // if (deposit.totalDeposit < depositAmount) {
        // depositAmount = depositAmount - deposit.totalDeposit;
        _pullStackTokens(depositAmount);

        deposit.totalDeposit = deposit.totalDeposit + depositAmount;
        // }

        emit DEPOSIT(
            clusterDns,
            depositer,
            deposit.totalDeposit,
            deposit.lastTxTime,
            deposit.totalDripRatePerSecond
        );
    }

    function _rechargeAccountInternal(
        uint256 amount,
        address depositer,
        bytes32 clusterDns
    ) internal {
        Deposit storage deposit = deposits[depositer][clusterDns];
        deposit.totalDeposit = deposit.totalDeposit + amount;
        _pullStackTokens(amount);
    }

    function _withdrawFundsPartialInternal(
        uint256 amount,
        address depositer,
        bytes32 clusterDns
    ) internal {
        settleAccounts(depositer, clusterDns);
        Deposit storage deposit = deposits[depositer][clusterDns];
        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor
        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);
        require(amount < deposit.totalDeposit, "Insufficient deposit balance");
        _withdraw(
            0,
            amount,
            msg.sender,
            clusterOwner,
            clusterDns,
            qualityFactor
        );
        deposit.totalDeposit = deposit.totalDeposit - amount;
    }

    // Is this a Refund function???

    function _settleBalances(address depositer, bytes32 clusterDns) internal {
        uint256 currentTime = block.timestamp;
        Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 elapsedTime = currentTime - deposit.lastTxTime;
        deposit.lastTxTime = currentTime;
        uint256 utilisedFunds = elapsedTime * deposit.totalDripRatePerSecond;
        uint256 withdrawAmount;
        if (utilisedFunds >= deposit.totalDeposit) {
            utilisedFunds = deposit.totalDeposit;
            withdrawAmount = 0;
        } else {
            withdrawAmount = deposit.totalDeposit - utilisedFunds;
        }

        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor
        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);

        _withdraw(
            utilisedFunds,
            withdrawAmount,
            depositer,
            clusterOwner,
            clusterDns,
            qualityFactor
        );

        delete deposits[depositer][clusterDns];

        emit WITHDRAW(
            depositer,
            deposit.totalDeposit,
            withdrawAmount,
            deposit.lastTxTime
        );
    }

    function _calcResourceUnitsPrice(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 pricePerUnit = IResourceFeed(resourceFeed).getResourcePrice(
            clusterDns,
            resourceName
        );
        uint256 priceInStack = stackToUSDT(pricePerUnit);
        return priceInStack * resourceUnits;
    }

    function _calcResourceUnitsDripRate(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
        .getResourceDripRate(clusterDns, resourceName);
        return dripRatePerUnit * resourceUnits;
    }

    function _pullStackTokens(uint256 amount) internal {
        IERC20(stackToken).transferFrom(msg.sender, address(this), amount);
    }

    function _getQuote(
        uint256 _amountIn,
        address _fromTokenAddress,
        address _toTokenAddress
    ) internal view returns (uint256 amountOut) {
        address pair = IUniswapV2Factory(factory).getPair(
            _fromTokenAddress,
            _toTokenAddress
        );
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pair)
        .getReserves();
        address token0 = IUniswapV2Pair(pair).token0();
        (uint256 reserveIn, uint256 reserveOut) = token0 == _fromTokenAddress
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountInWithFee = _amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = (numerator / denominator);
    }

    function stackToUSDT(uint256 _stackAmount)
        public
        view
        returns (uint256 USDVALUE)
    {
        uint256 ETHVALUE = _getQuote(_stackAmount, stackToken, weth);
        USDVALUE = _getQuote(ETHVALUE, weth, usdt);
    }

    function usdtToSTACK(uint256 _usdtAmount)
        public
        view
        returns (uint256 STACKVALUE)
    {
        uint256 ETHVALUE = _getQuote(_usdtAmount, usdt, weth);
        STACKVALUE = _getQuote(ETHVALUE, weth, stackToken);
    }

    function stackToToken(address _token, uint256 _stackAmount)
        public
        view
        returns (uint256 TOKENVALUE)
    {
        uint256 ETHVALUE = _getQuote(_stackAmount, stackToken, weth);
        TOKENVALUE = _getQuote(ETHVALUE, weth, _token);
    }

    function _swapTokensInternal(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 amountOutMin
    ) internal returns (uint256 tokenBought) {
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = router.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            block.timestamp + 1200
        )[path.length - 1];
    }

    function _withdraw(
        uint256 utilisedFunds,
        uint256 withdrawAmount,
        address depositer,
        address clusterOwner,
        bytes32 clusterDns,
        uint256 qualityFactor
    ) internal {
        // Check the quality Facror and reduce a portion of payout if necessery.
        uint256 utilisedFundsAfterQualityCheck = (qualityFactor *
            (10**18) *
            utilisedFunds) /
            100 /
            (10**18);

        if (utilisedFundsAfterQualityCheck > 0) {
            WithdrawSetting storage withdrawsetup = withdrawsettings[
                clusterOwner
            ];
            if (withdrawsetup.percent > 0) {
                uint256 stacktoToken = (utilisedFundsAfterQualityCheck *
                    withdrawsetup.percent) / 10000;
                uint256 stackWithdraw = utilisedFundsAfterQualityCheck -
                    stacktoToken;
                // Uniswap Swap Here. NEEDS TESTING!
                _swapTokens(stackToken, withdrawsetup.token, 0, stacktoToken);
                IERC20(withdrawsetup.token).transfer(
                    clusterOwner,
                    IERC20(withdrawsetup.token).balanceOf(address(this))
                );
                IERC20(stackToken).transfer(clusterOwner, stackWithdraw);
            }
            // utilisedFundsAfterQualityCheck
            IERC20(stackToken).transfer(
                clusterOwner,
                utilisedFundsAfterQualityCheck
            );
            uint256 penalty = utilisedFunds - utilisedFundsAfterQualityCheck;
            if (penalty > 0) {
                IERC20(stackToken).transfer(dao, penalty);
            }
        }

        if (withdrawAmount > 0) {
            // Transfer out the remaining funds to msg.sender
            IERC20(stackToken).transfer(depositer, withdrawAmount);
            delete deposits[depositer][clusterDns];
        }

        stackEarned = stackEarned + utilisedFunds;
    }

    function _swapTokens(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 amountOutMin,
        uint256 amountInMax
    ) internal returns (uint256 tokenBought) {
        address[] memory path = new address[](2);
        path[0] = _FromTokenContractAddress;
        path[1] = _ToTokenContractAddress;

        tokenBought = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountOutMin,
            amountInMax,
            path,
            address(this),
            block.timestamp + 1200
        )[path.length - 1];
    }
}
