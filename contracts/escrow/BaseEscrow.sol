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
import "./EscrowLib.sol";

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
     * @param Factory Contract of DEX
     * @param Router Contract of DEX
     * @param Dao address
     * @param Gov address
     * @param WETH Contract Address
     * @param USDT Contract Address
     * @param Oracle Contract Address
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
    function setVariableFees(uint16 _govFee, uint16 _daoFee) public onlyOwner {
        govFee = _govFee;
        daoFee = _daoFee;
    }

    /*
     * @title Update the Platform fee receiver address
     * @param DAO address
     * @param Governance address
     * @param Oracle address
     * @param Resource Feed address
     * @param Staking address
     * @param Dns Store address
     * @dev Could only be invoked by the contract owner
     */

    function setAddressSettings(
        address _daoAddress,
        address _govAddress,
        address _oracle,
        address _resourceFeed,
        address _staking,
        address _dnsStore
    ) public onlyOwner {
        dao = _daoAddress;
        gov = _govAddress;
        oracle = _oracle;
        resourceFeed = _resourceFeed;
        staking = _staking;
        dnsStore = _dnsStore;
    }

    /*
     * @title Update the Platform Minimum
     * @param Minimum resource purchaise amount.
     * @dev Could only be invoked by the contract owner
     */

    function setMinPurchase(uint256 minStackAmount) public onlyOwner {
        minPurchase = minStackAmount;
    }

    /*
     * @title Update the Platform Minimum
     * @param Minimum resource purchaise amount.
     * @dev Could only be invoked by the contract owner
     */

    function getDeposits(address depositer, bytes32 clusterDns)
        external
        view
        returns (EscrowLib.Deposit memory)
    {
        return deposits[depositer][clusterDns];
    }

    function getResouceVar(uint8 _id) external view returns (string memory) {
        return resourceVar[_id];
    }

    /*
     * @title Withdraw a depositer funds
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     * @dev Could only be invoked by the contract owner
     */
    function withdrawFundsAdmin(address depositer, bytes32 clusterDns)
        public
        onlyOwner
    {
        _settleAndWithdraw(depositer, clusterDns, 0, true);
    }

    /*
     * @title Emergency refund
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     * @dev Could only be invoked by the cluster owner
     */
    function EmergencyRefundByClusterOwner(
        address depositer,
        bytes32 clusterDns
    ) public {
        (address clusterOwner, , , , , , , , , ) = IDnsClusterMetadataStore(
            dnsStore
        ).dnsToClusterMetadata(clusterDns);
        require(clusterOwner == msg.sender);
        EscrowLib.Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 depositAmount = deposit.totalDeposit;
        require(depositAmount > 0);
        reduceClusterCap(clusterDns, depositer);
        delete deposits[depositer][clusterDns];
        IERC20(stackToken).transfer(depositer, depositAmount);
    }

    /*
     * @title Settle Depositer Account
     * @param Depositer Address
     * @param ClusterDNS that is being settled
     */

    function settleAccounts(address depositer, bytes32 clusterDns) public {
        uint256 utilisedFunds;
        EscrowLib.Deposit storage deposit = deposits[depositer][clusterDns];
        uint256 elapsedTime = block.timestamp.sub(deposit.lastTxTime);
        deposit.lastTxTime = block.timestamp;

        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,
            ,
            ,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);
        uint256 MaxPossibleElapsedTime;
        if (
            IPriceOracle(oracle).usdtToSTACKOracle(
                deposit.totalDripRatePerSecond
            ) == 0
        ) MaxPossibleElapsedTime = ~uint256(0);
        else
            MaxPossibleElapsedTime = deposit.totalDeposit.div(
                IPriceOracle(oracle).usdtToSTACKOracle(
                    deposit.totalDripRatePerSecond
                )
            );

        if (elapsedTime > MaxPossibleElapsedTime) {
            elapsedTime = MaxPossibleElapsedTime;
            utilisedFunds = deposit.totalDeposit;
        } else {
            utilisedFunds = elapsedTime.mul(deposit.totalDripRatePerSecond);
            utilisedFunds = IPriceOracle(oracle).usdtToSTACKOracle(
                utilisedFunds
            );
        }

        // Add fees to utilised funds.
        uint256 VarDaoGovFee = _AddFeesAndDeduct(utilisedFunds);

        utilisedFunds = utilisedFunds.add(VarDaoGovFee);
        if (
            deposit.notWithdrawable > 0 &&
            deposit.notWithdrawable >= utilisedFunds
        ) deposit.notWithdrawable = deposit.notWithdrawable.sub(utilisedFunds);
        if (deposit.notWithdrawable <= utilisedFunds)
            deposit.notWithdrawable = 0;
        if (utilisedFunds >= deposit.totalDeposit) {
            utilisedFunds = deposit.totalDeposit.sub(VarDaoGovFee);
            reduceClusterCap(clusterDns, depositer);
            delete deposits[depositer][clusterDns];
            removeClusterAddresConnection(
                clusterDns,
                findAddressIndex(clusterDns, depositer)
            );
        } else {
            deposit.totalDeposit = deposit.totalDeposit.sub(utilisedFunds);
            utilisedFunds = utilisedFunds.sub(VarDaoGovFee);
        }

        _withdraw(utilisedFunds, 0, depositer, clusterOwner, qualityFactor);
    }

    function reduceClusterCap(bytes32 clusterDns, address depositer) internal {
        if (resourceCapacityState[clusterDns].resourceOne > 0)
            resourceCapacityState[clusterDns]
                .resourceOne = resourceCapacityState[clusterDns]
                .resourceOne
                .sub(deposits[depositer][clusterDns].resourceOneUnits);
        if (resourceCapacityState[clusterDns].resourceTwo > 0)
            resourceCapacityState[clusterDns]
                .resourceTwo = resourceCapacityState[clusterDns]
                .resourceTwo
                .sub(deposits[depositer][clusterDns].resourceTwoUnits);
        if (resourceCapacityState[clusterDns].resourceThree > 0)
            resourceCapacityState[clusterDns]
                .resourceThree = resourceCapacityState[clusterDns]
                .resourceThree
                .sub(deposits[depositer][clusterDns].resourceThreeUnits);
        if (resourceCapacityState[clusterDns].resourceFour > 0)
            resourceCapacityState[clusterDns]
                .resourceFour = resourceCapacityState[clusterDns]
                .resourceFour
                .sub(deposits[depositer][clusterDns].resourceFourUnits);
        if (resourceCapacityState[clusterDns].resourceFive > 0)
            resourceCapacityState[clusterDns]
                .resourceFive = resourceCapacityState[clusterDns]
                .resourceFive
                .sub(deposits[depositer][clusterDns].resourceFiveUnits);
        if (resourceCapacityState[clusterDns].resourceSix > 0)
            resourceCapacityState[clusterDns]
                .resourceSix = resourceCapacityState[clusterDns]
                .resourceSix
                .sub(deposits[depositer][clusterDns].resourceSixUnits);
        if (resourceCapacityState[clusterDns].resourceSeven > 0)
            resourceCapacityState[clusterDns]
                .resourceSeven = resourceCapacityState[clusterDns]
                .resourceSeven
                .sub(deposits[depositer][clusterDns].resourceSevenUnits);
        if (resourceCapacityState[clusterDns].resourceEight > 0)
            resourceCapacityState[clusterDns]
                .resourceEight = resourceCapacityState[clusterDns]
                .resourceEight
                .sub(deposits[depositer][clusterDns].resourceEightUnits);
    }

    /*
     * @title Deduct Variable Fees
     * @param Utilised funds in stack
     * @param Time since the last deposit or settelment
     * @param Resource Units.
     * @dev Part of the settelmet functions
     */

    function _AddFeesAndDeduct(uint256 utilisedFunds)
        internal
        returns (uint256)
    {
        uint256 variableDaoFee = utilisedFunds.mul(daoFee).div(10000);
        uint256 variableGovFee = utilisedFunds.mul(govFee).div(10000);

        if (variableDaoFee > 0)
            IERC20(stackToken).transfer(dao, variableDaoFee);
        if (variableGovFee > 0)
            IERC20(stackToken).transfer(gov, variableGovFee);
        return variableDaoFee.add(variableGovFee);
    }

    /*
     * @title Deposit Stack to start using the cluster
     * @param Cluster DNS
     * @param ResourcesFees. A list of 8 item that includes fee per resource. Available resources and their order -> resourceVar(id) (1-8)
     * @param Amount of Stack to Deposit to use these recources.
     * @param The address of resource buyer.
     * @param is it withdrawable
     * @param Is it a grant
     * @dev Part of the settelmet functions
     */

    function _createDepositInternal(
        bytes32 clusterDns,
        EscrowLib.ResourceUnits memory resourceUnits,
        uint256 depositAmount,
        address depositer,
        bool withdrawable,
        bool grant
    ) internal {
        (, , , , , , , bool active, , ) = IDnsClusterMetadataStore(dnsStore)
            .dnsToClusterMetadata(clusterDns);
        require(active == true);

        EscrowLib.Deposit storage deposit = deposits[depositer][clusterDns];

        _capacityCheck(clusterDns, resourceUnits);

        deposit.lastTxTime = block.timestamp;
        deposit.resourceOneUnits = resourceUnits.resourceOne; //CPU
        deposit.resourceTwoUnits = resourceUnits.resourceTwo; // diskSpaceUnits
        deposit.resourceThreeUnits = resourceUnits.resourceThree; // bandwidthUnits
        deposit.resourceFourUnits = resourceUnits.resourceFour; // memoryUnits
        deposit.resourceFiveUnits = resourceUnits.resourceFive;
        deposit.resourceSixUnits = resourceUnits.resourceSix;
        deposit.resourceSevenUnits = resourceUnits.resourceSeven;
        deposit.resourceEightUnits = resourceUnits.resourceEight;

        deposit.totalDripRatePerSecond = getResourcesDripRateInUSDT(
            clusterDns,
            resourceUnits
        );

        addClusterAddresConnection(clusterDns, depositer);
        if (grant == false) _pullStackTokens(depositAmount);
        if (withdrawable == false) {
            deposit.notWithdrawable = depositAmount;
        }
        deposit.totalDeposit = deposit.totalDeposit.add(depositAmount);
    }

    function _capacityCheck(
        bytes32 clusterDns,
        EscrowLib.ResourceUnits memory resourceUnits
    ) internal {
        resourceCapacityState[clusterDns].resourceOne = resourceCapacityState[
            clusterDns
        ].resourceOne.add(resourceUnits.resourceOne);
        resourceCapacityState[clusterDns].resourceTwo = resourceCapacityState[
            clusterDns
        ].resourceTwo.add(resourceUnits.resourceTwo);
        resourceCapacityState[clusterDns].resourceThree = resourceCapacityState[
            clusterDns
        ].resourceThree.add(resourceUnits.resourceThree);
        resourceCapacityState[clusterDns].resourceFour = resourceCapacityState[
            clusterDns
        ].resourceFour.add(resourceUnits.resourceFour);
        resourceCapacityState[clusterDns].resourceFive = resourceCapacityState[
            clusterDns
        ].resourceFive.add(resourceUnits.resourceFive);
        resourceCapacityState[clusterDns].resourceSix = resourceCapacityState[
            clusterDns
        ].resourceSix.add(resourceUnits.resourceSix);
        resourceCapacityState[clusterDns].resourceSeven = resourceCapacityState[
            clusterDns
        ].resourceSeven.add(resourceUnits.resourceSeven);
        resourceCapacityState[clusterDns].resourceEight = resourceCapacityState[
            clusterDns
        ].resourceEight.add(resourceUnits.resourceEight);

        bool OverLimit = false;
        if (
            resourceUnits.resourceOne > 1 &&
            resourceUnits.resourceOne >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceOne
        ) OverLimit = true;
        if (
            resourceUnits.resourceTwo > 1 &&
            resourceUnits.resourceTwo >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceTwo
        ) OverLimit = true;
        if (
            resourceUnits.resourceThree > 1 &&
            resourceUnits.resourceThree >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceThree
        ) OverLimit = true;
        if (
            resourceUnits.resourceFour > 1 &&
            resourceUnits.resourceFour >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceFour
        ) OverLimit = true;
        if (
            resourceUnits.resourceFive > 1 &&
            resourceUnits.resourceFive >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceFive
        ) OverLimit = true;
        if (
            resourceUnits.resourceSix > 1 &&
            resourceUnits.resourceSix >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceSix
        ) OverLimit = true;
        if (
            resourceUnits.resourceSeven > 1 &&
            resourceUnits.resourceSeven >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceSeven
        ) OverLimit = true;
        if (
            resourceUnits.resourceEight > 1 &&
            resourceUnits.resourceEight >
            IResourceFeed(resourceFeed)
                .getResourceMaxCapacity(clusterDns)
                .resourceEight
        ) OverLimit = true;
        require(OverLimit == false);
    }

    function _rechargeAccountInternal(
        uint256 amount,
        address depositer,
        bytes32 clusterDns,
        bool withdrawable,
        bool grant
    ) internal {
        EscrowLib.Deposit storage deposit = deposits[depositer][clusterDns];
        deposit.totalDeposit = deposit.totalDeposit.add(amount);
        // If fund's given though grant, make them not withdrawable.
        if (withdrawable == false) {
            deposit.notWithdrawable = deposit.notWithdrawable.add(amount);
        }
        if (grant == false) _pullStackTokens(amount);
    }

    function _settleAndWithdraw(
        address depositer,
        bytes32 clusterDns,
        uint256 amount,
        bool everything
    ) internal {
        uint256 withdrawAmount;
        settleAccounts(depositer, clusterDns);
        EscrowLib.Deposit storage deposit = deposits[depositer][clusterDns];
        require(deposit.totalDeposit.sub(deposit.notWithdrawable) > amount);
        (
            address clusterOwner,
            ,
            ,
            ,
            ,
            ,
            uint256 qualityFactor,
            ,
            ,

        ) = IDnsClusterMetadataStore(dnsStore).dnsToClusterMetadata(clusterDns);
        if (everything == false) {
            require(amount < deposit.totalDeposit);
            deposit.totalDeposit = deposit.totalDeposit.sub(amount);
            withdrawAmount = amount;
        } else {
            withdrawAmount = deposit.totalDeposit.sub(deposit.notWithdrawable);

            if (deposit.notWithdrawable == 0) {
                delete deposits[depositer][clusterDns];
                removeClusterAddresConnection(
                    clusterDns,
                    findAddressIndex(clusterDns, depositer)
                );
            } else {
                deposit.totalDeposit = deposit.totalDeposit.sub(withdrawAmount);
            }
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
        for (uint256 i = nrOfAccounts; i > 0; i--) {
            settleAccounts(clusterUsers[clusterDns][i - 1], clusterDns);
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

    function _calcResourceUnitsDripRateUSDT(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
            .getResourceDripRateUSDT(clusterDns, resourceName);
        return dripRatePerUnit.mul(resourceUnits);
    }

    function _calcResourceUnitsDripRateSTACK(
        bytes32 clusterDns,
        string memory resourceName,
        uint256 resourceUnits
    ) internal view returns (uint256) {
        uint256 dripRatePerUnit = IResourceFeed(resourceFeed)
            .getResourceDripRateUSDT(clusterDns, resourceName);
        return usdtToSTACK(dripRatePerUnit.mul(resourceUnits));
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
        amountOut = numerator.div(denominator);
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

    function stackToTokenRate(address _token, uint256 _stackAmount)
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
        uint256 utilisedFundsAfterQualityCheck = qualityFactor
            .mul(10**18)
            .mul(utilisedFunds)
            .div(100)
            .div(10**18);

        if (utilisedFundsAfterQualityCheck > 0) {
            EscrowLib.WithdrawSetting storage withdrawsetup = withdrawSettings[
                clusterOwner
            ];
            if (withdrawsetup.percent > 0) {
                uint256 stacktoToken = utilisedFundsAfterQualityCheck
                    .mul(withdrawsetup.percent)
                    .div(10000);
                uint256 stackWithdraw = utilisedFundsAfterQualityCheck.sub(
                    stacktoToken
                );

                IERC20(stackToken).approve(
                    address(router),
                    999999999999999999999999999999
                );
                _swapTokens(
                    stackToken,
                    withdrawsetup.token,
                    stacktoToken,
                    stackToTokenRate(withdrawsetup.token, stacktoToken),
                    clusterOwner
                );
                IERC20(stackToken).transfer(clusterOwner, stackWithdraw);
            } else {
                IERC20(stackToken).transfer(
                    clusterOwner,
                    utilisedFundsAfterQualityCheck
                );
            }

            uint256 penalty = utilisedFunds.sub(utilisedFundsAfterQualityCheck);
            if (penalty > 0) {
                IERC20(stackToken).transfer(dao, penalty);
            }
        }

        if (withdrawAmount > 0) {
            IERC20(stackToken).transfer(depositer, withdrawAmount);
        }
    }

    function _swapTokens(
        address _FromTokenContractAddress,
        address _ToTokenContractAddress,
        uint256 amountOut,
        uint256 amountInMax,
        address forWallet
    ) internal returns (uint256 tokenBought) {
        address[] memory path = new address[](3);
        path[0] = _FromTokenContractAddress;
        path[1] = weth;
        path[2] = _ToTokenContractAddress;

        tokenBought = IUniswapV2Router02(router).swapExactTokensForTokens(
            amountOut,
            amountInMax,
            path,
            forWallet,
            block.timestamp + 1200
        )[path.length - 1];
    }

    /*
     * @title Define Recource Strings
     * @param Resource ID from 1 to 8
     * @param Name of the resource.
     */

    function defineResourceVar(uint8 resouceNr, string memory resourceName)
        public
        onlyOwner
    {
        require(resouceNr <= 8 && resouceNr != 0);
        resourceVar[resouceNr] = resourceName;
    }

    /*
     * @title Fetches the cummulative dripRate of Resources
     * @param ResourcesFees. A list of 8 item that includes fee per resource. Available resources and their order -> resourceVar(id) (1-8)
     * @return Total resources drip rate measured in USDT
     */
    function getResourcesDripRateInUSDT(
        bytes32 clusterDns,
        EscrowLib.ResourceUnits memory resourceUnits
    ) public view returns (uint256) {
        uint256 amountInUSDT = _calcResourceUnitsDripRateUSDT(
            clusterDns,
            resourceVar[1],
            resourceUnits.resourceOne
        ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[2],
                resourceUnits.resourceTwo
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[3],
                resourceUnits.resourceThree
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[4],
                resourceUnits.resourceFour
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[5],
                resourceUnits.resourceFive
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[6],
                resourceUnits.resourceSix
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[7],
                resourceUnits.resourceSeven
            ) +
            _calcResourceUnitsDripRateUSDT(
                clusterDns,
                resourceVar[8],
                resourceUnits.resourceEight
            );
        return amountInUSDT;
    }
}
