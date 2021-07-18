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
import "../oracle/IPriceOracle.sol";
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
        address _usdt,
        address _oracle
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
        oracle = _oracle;
    }

    /*
     * @title Update the Platform Variable Fees. These fees are in percentages.
     * @param Updated Platform Governance Fee
     * @param Updated Platform DAO Fee
     * @dev Could only be invoked by the contract owner
     */
    function setVariableFees(uint256 _govFee, uint256 _daoFee)
        public
        onlyOwner
    {
        govFee = _govFee;
        daoFee = _daoFee;
    }

    /*
     * @title Update the Platform fixed Fees. These fees are in USDT value.
     * @param Allocated for DAO or Governance
     * @param CPU fee in USD.
     * @param Disk fee in USD.
     * @param Bandwith fee in USD.
     * @param Memory fee in USD.
     * @dev Could only be invoked by the contract owner
     */

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

    /*
     * @title Update the Platform fee receiver address
     * @param DAO address
     * @param Governance address
     * @dev Could only be invoked by the contract owner
     */

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
     * @param ClusterDNS that is being settled
     * @dev Could only be invoked by the contract owner
     */
    function withDrawFundsAdmin(address depositer, bytes32 clusterDns)
        public
        onlyOwner
    {
        _settleAndWithdraw(depositer, clusterDns, 0, true);
    }

    /*
     * @title Settle Depositer Account
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     */
    uint256 public print3;
    uint256 public print4;

    function settleAccounts(address depositer, bytes32 clusterDns) public {
        uint256 utilisedFunds;
        uint256 currentTime = block.timestamp;
        Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 elapsedTime = currentTime - deposit.lastTxTime;
        deposit.lastTxTime = currentTime;

        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);

        uint256 MaxPossibleElapsedTime = deposit.totalDeposit /
            IPriceOracle(oracle).usdtToSTACKOracle(
                deposit.totalDripRatePerSecond
            );

        if (elapsedTime > MaxPossibleElapsedTime) {
            elapsedTime = MaxPossibleElapsedTime;
            utilisedFunds = deposit.totalDeposit;
        } else {
            utilisedFunds = elapsedTime * deposit.totalDripRatePerSecond;
            utilisedFunds = IPriceOracle(oracle).usdtToSTACKOracle(
                utilisedFunds
            );
        }
        print3 = elapsedTime;

        // Add fees to utilised funds.
        (
            uint256 fixAndVarDaoFee,
            uint256 fixAndVarGovFee
        ) = _AddFixedFeesAndDeduct(
            utilisedFunds,
            elapsedTime,
            deposit.cpuCoresUnits,
            deposit.diskSpaceUnits,
            deposit.bandwidthUnits,
            deposit.memoryUnits
        );

        utilisedFunds = utilisedFunds + fixAndVarDaoFee + fixAndVarGovFee;
        print4 = utilisedFunds;
        if (utilisedFunds >= deposit.totalDeposit) {
            utilisedFunds =
                deposit.totalDeposit -
                (fixAndVarDaoFee + fixAndVarGovFee);
            delete deposits[depositer][clusterDns];
            removeClusterAddresConnection(
                clusterDns,
                findAddressIndex(clusterDns, depositer)
            );
        } else {
            deposit.totalDeposit = deposit.totalDeposit - utilisedFunds;
            utilisedFunds = utilisedFunds - (fixAndVarDaoFee + fixAndVarGovFee);
        }

        _withdraw(utilisedFunds, 0, depositer, clusterOwner, qualityFactor);
    }

    /*
     * @title Deduct Fixed and Variable Fees
     * @param Utilised funds in stack
     * @param Time since the last deposit / settelment
     * @param CPU Units Purchaised
     * @param Disk Space Units Purchaised
     * @param Bandwith Units Purchaised
     * @param Memory Units Purchaised
     * @dev Part of the settelmet functions
     */
    uint256 public printnr1 = 0;
    uint256 public printnr2 = 0;

    function _AddFixedFeesAndDeduct(
        uint256 utilisedFunds,
        uint256 timeelapsed,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits
    ) internal returns (uint256, uint256) {
        ResourceFees storage govFixedFees = fixedResourceFee["gov"];
        ResourceFees storage daoFixedFees = fixedResourceFee["dao"];
        uint256 daoFeesFixed;
        uint256 govFeesFixed;
        printnr2 = utilisedFunds;
        if (cpuCoresUnits > 0) {
            govFeesFixed =
                govFeesFixed +
                (cpuCoresUnits * govFixedFees.cpuFee * timeelapsed);
            daoFeesFixed =
                daoFeesFixed +
                (cpuCoresUnits * daoFixedFees.cpuFee * timeelapsed);
        }
        if (diskSpaceUnits > 0) {
            govFeesFixed =
                govFeesFixed +
                (cpuCoresUnits * govFixedFees.diskFee * timeelapsed);
            daoFeesFixed =
                daoFeesFixed +
                (cpuCoresUnits * daoFixedFees.diskFee * timeelapsed);
        }
        if (bandwidthUnits > 0) {
            govFeesFixed =
                govFeesFixed +
                (cpuCoresUnits * govFixedFees.bandwidthFee * timeelapsed);
            daoFeesFixed =
                daoFeesFixed +
                (cpuCoresUnits * daoFixedFees.bandwidthFee * timeelapsed);
        }
        if (memoryUnits > 0) {
            govFeesFixed =
                govFeesFixed +
                (cpuCoresUnits * govFixedFees.memoryFee * timeelapsed);
            daoFeesFixed =
                daoFeesFixed +
                (cpuCoresUnits * daoFixedFees.memoryFee * timeelapsed);
        }
        (uint256 variableDaoFee, uint256 variableGovFee) = _AddVariablesFees(
            utilisedFunds
        );
        uint256 daoFeesFixedAndVariable = daoFeesFixed + variableDaoFee;
        uint256 govFeesFixedAndVariable = govFeesFixed + variableGovFee;
        printnr1 = variableDaoFee;
        if (daoFeesFixed > 0)
            IERC20(stackToken).transfer(dao, daoFeesFixedAndVariable);
        if (govFeesFixed > 0)
            IERC20(stackToken).transfer(gov, govFeesFixedAndVariable);
        return (daoFeesFixedAndVariable, govFeesFixedAndVariable);
    }

    /*
     * @title Part of AddFixedFeesAndDeduct
     * @param Utilised funds in stack
     * @dev Part of the settelmet functions
     */

    function _AddVariablesFees(uint256 utilisedFunds)
        internal
        view
        returns (uint256, uint256)
    {
        // Settle Dao and Gov
        uint256 forDao = (utilisedFunds * daoFee) / 10000;
        uint256 forGov = (utilisedFunds * govFee) / 10000;

        return (forDao, forGov);
    }

    /*
     * @title Deposit Stack to start using the cluster
     * @param Cluster DNS
     * @param Amount of CPU Units that will be used
     * @param Amount of Disk Space that will be used
     * @param Amount of Bandwith that will be used
     * @param Amount of Memory that will be used
     * @param Amount of Stack to Deposit to use these recources.
     * @param The address of resource buyer.
     * @dev Part of the settelmet functions
     */

    function _createDepositInternal(
        bytes32 clusterDns,
        uint256 cpuCoresUnits,
        uint256 diskSpaceUnits,
        uint256 bandwidthUnits,
        uint256 memoryUnits,
        uint256 depositAmount,
        address depositer
    ) internal {
        (, , , , , , , bool active) = IDnsClusterMetadataStore(dnsStore)
        .dnsToClusterMetadata(clusterDns);
        require(active == true, "Deposits are disabled");

        Deposit storage deposit = deposits[depositer][clusterDns];

        deposit.lastTxTime = block.timestamp;
        deposit.cpuCoresUnits = cpuCoresUnits;
        deposit.diskSpaceUnits = diskSpaceUnits;
        deposit.bandwidthUnits = bandwidthUnits;
        deposit.memoryUnits = memoryUnits;

        deposit.totalDripRatePerSecond =
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                "cpu",
                deposit.cpuCoresUnits
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                "memory",
                deposit.memoryUnits
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                "disk",
                deposit.diskSpaceUnits
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                "bandwidth",
                deposit.bandwidthUnits
            );

        addClusterAddresConnection(clusterDns, depositer);
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
        (, , , , , , , bool active) = IDnsClusterMetadataStore(dnsStore)
        .dnsToClusterMetadata(clusterDns);
        require(active == true, "Deposits are disabled");
        Deposit storage deposit = deposits[depositer][clusterDns];
        deposit.totalDeposit = deposit.totalDeposit + amount;
        _pullStackTokens(amount);
    }

    function _settleAndWithdraw(
        address depositer,
        bytes32 clusterDns,
        uint256 amount,
        bool everything
    ) internal {
        uint256 withdrawAmount;
        settleAccounts(depositer, clusterDns);
        Deposit storage deposit = deposits[depositer][clusterDns];
        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);
        if (everything == false) {
            require(
                amount < deposit.totalDeposit,
                "Insufficient deposit balance"
            );
            deposit.totalDeposit = deposit.totalDeposit - amount;
            withdrawAmount = amount;
        } else {
            withdrawAmount = deposit.totalDeposit;
            delete deposits[depositer][clusterDns];
            removeClusterAddresConnection(
                clusterDns,
                findAddressIndex(clusterDns, depositer)
            );
        }

        _withdraw(0, withdrawAmount, depositer, clusterOwner, qualityFactor);
    }

    /*
     * @title Settle multiple accounts in one transaction
     * @param Cluster DNS
     * @param amount of accounts to settle.
     */

    function settleMultipleAccounts(bytes32 clusterDns, uint256 nrOfAccounts)
        public
    {
        for (uint256 i; nrOfAccounts > i; i++) {
            settleAccounts(clusterUsers[clusterDns][i], clusterDns);
        }
    }

    /*
     * @title Find the index for ClusterDNS => Address link
     * @param Cluster DNS
     * @param Depositer Address
     * @dev Part of the settelmet function
     */

    function findAddressIndex(bytes32 clusterDns, address _address)
        internal
        view
        returns (uint256)
    {
        for (uint256 i; i < clusterUsers[clusterDns].length; i++) {
            if (clusterUsers[clusterDns][i] == _address) {
                return i;
            }
        }
    }

    /*
     * @title Remove link between ClusterDNS => Address
     * @param Cluster DNS
     * @param List index
     * @dev Part of the settelmet function
     */

    function removeClusterAddresConnection(bytes32 clusterDns, uint256 index)
        internal
    {
        for (uint256 a = index; a < clusterUsers[clusterDns].length - 1; a++) {
            clusterUsers[clusterDns][a] = clusterUsers[clusterDns][a + 1];
        }
        clusterUsers[clusterDns].pop();
    }

    /*
     * @title Create link between ClusterDNS => Address
     * @param Cluster DNS
     * @param Deployer wallet address
     * @dev Part of deposit function
     */

    function addClusterAddresConnection(bytes32 clusterDns, address _address)
        internal
    {
        clusterUsers[clusterDns].push(_address);
    }

    /*
     * @title Create link between ClusterDNS => Address
     * @param Cluster DNS
     * @param Deployer wallet address
     * @dev Part of deposit function
     */

    function _calcResourceUnitsPriceUSDT(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 pricePerUnitUSDT = IResourceFeed(resourceFeed)
        .getResourcePriceUSDT(clusterDns, resourceName);
        return pricePerUnitUSDT * resourceUnits;
    }

    function _calcResourceUnitsDripRateUSDT(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
        .getResourceDripRateUSDT(clusterDns, resourceName);
        return dripRatePerUnit * resourceUnits;
    }

    function _calcResourceUnitsDripRateSTACK(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
        .getResourceDripRateUSDT(clusterDns, resourceName);
        return usdtToSTACK(dripRatePerUnit * resourceUnits);
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

    function _withdraw(
        uint256 utilisedFunds,
        uint256 withdrawAmount,
        address depositer,
        address clusterOwner,
        uint256 qualityFactor
    ) internal {
        // Check the quality Facror and reduce a portion of payout if necessery.
        uint256 utilisedFundsAfterQualityCheck = (qualityFactor *
            (10**18) *
            utilisedFunds) /
            100 /
            (10**18);

        if (utilisedFundsAfterQualityCheck > 0) {
            WithdrawSetting storage withdrawsetup = withdrawSettings[
                clusterOwner
            ];
            if (withdrawsetup.percent > 0) {
                uint256 stacktoToken = (utilisedFundsAfterQualityCheck *
                    withdrawsetup.percent) / 10000;
                uint256 stackWithdraw = utilisedFundsAfterQualityCheck -
                    stacktoToken;

                IERC20(stackToken).approve(
                    address(router),
                    999999999999999999999999999999
                );
                _swapTokens(
                    stackToken,
                    withdrawsetup.token,
                    stacktoToken,
                    0,
                    clusterOwner
                );
                IERC20(stackToken).transfer(clusterOwner, stackWithdraw);
            } else {
                IERC20(stackToken).transfer(
                    clusterOwner,
                    utilisedFundsAfterQualityCheck
                );
            }

            uint256 penalty = utilisedFunds - utilisedFundsAfterQualityCheck;
            if (penalty > 0) {
                IERC20(stackToken).transfer(dao, penalty);
            }
        }

        if (withdrawAmount > 0) {
            IERC20(stackToken).transfer(depositer, withdrawAmount);
        }

        stackEarned = stackEarned + utilisedFunds;
    }

    function _swapTokens(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 amountOutMin,
        uint256 amountInMax,
        address forWallet
    ) internal returns (uint256 tokenBought) {
        address[] memory path = new address[](3);
        path[0] = _FromTokenContractAddress;
        path[1] = weth;
        path[2] = _ToTokenContractAddress;

        tokenBought = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountOutMin,
            amountInMax,
            path,
            forWallet,
            block.timestamp + 1200
        )[path.length - 1];
    }
}
