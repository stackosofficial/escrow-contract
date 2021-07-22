pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
import "./BaseEscrow.sol";

// /// @title StackEscrow is derived from the BaseEscrow Contract
// /// @notice Major contract responsible for user to purchase or update StackOS's resources from Stack Token
contract StackEscrow is BaseEscrow {
    /*
     * @dev - constructor (being called at contract deployment)
     * @param Address of stackToken deployed contract
     * @param Address of ResourceFeed deployed contract
     * @param Address of Staking deployed contract
     * @param Address of DnsClusterMetadataStore deployed contract
     * @param Factory Contract of DEX
     * @param Router Contract of DEX
     * @param DAO Address
     * @param Governance Address
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
            _usdt,
            _oracle
        )
    {
        stackToken = _stackToken;
    }

    /*
     * @title Purchase the resources using STACK token
     * @param DNS Cluster
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     * @param Deposit Amount in stack token
     * @dev User should only invoke the function when performing initial deposit
     */
    function updateResourcesByStackAmount(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits,
        uint256 depositAmount
    ) public {
        Deposit storage deposit = deposits[msg.sender][clusterDns];
        require(deposit.lastTxTime == 0, "Not the first deposit");
        require(deposit.totalDeposit == 0, "Non zero amount already deposited");
        require(depositAmount > 0, "zero deposit amount");

        _createDepositInternal(
            clusterDns,
            resourceUnits,
            depositAmount,
            msg.sender,
            true,
            false
        );
    }

    /*
     * @title Update the user's resources from STACK token
     * @param DNS Cluster
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     * @dev User should have the Amount of Stack Token in his wallet that will be used for the resources he/she is accesseing
     */
    function updateResourcesFromStack(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits,
        uint256 depositAmount
    ) public {
        {
            Deposit storage deposit = deposits[msg.sender][clusterDns];
            if (deposit.lastTxTime > 0) {
                settleAccounts(msg.sender, clusterDns);
            }
        }

        _createDepositInternal(
            clusterDns,
            resourceUnits,
            depositAmount,
            msg.sender,
            true,
            false
        );
    }

    /*
     * @title Cluster Owner send a rebate in stack tokens to developers
     * @param Amount of Stack
     * @param Address for whom the rebate is being done
     * @param ClusterDNS to whom the rebate will be credited
     * @param Specify if the funds are withdrawable
     */

    function rebateAccount(
        uint256 amount,
        address account,
        bytes32 clusterDns,
        bool withdrawable
    ) public {
        address clusterOwner = IDnsClusterMetadataStore(dnsStore)
        .getClusterOwner(clusterDns);
        require(clusterOwner == msg.sender, "Not the cluster owner!");
        _rechargeAccountInternal(
            amount,
            account,
            clusterDns,
            withdrawable,
            false
        );
    }

    /*
     * @title Fetches the cummulative dripRate of Resources in STACK
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     * @return Total resources drip rate measured in STACK
     * @param Cluster DNS that will be checked for prices.
     */
    function getResourcesDripRateInSTACK(
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) public view returns (uint256) {
        uint256 amountInUSDT = getResourcesDripRateInUSDT(
            clusterDns,
            resourceUnits
        );
        uint256 amountInSTACK = usdtToSTACK(amountInUSDT);
        return amountInSTACK;
    }

    /*
     * @title TopUp the user's Account with input Amount
     * @param Amount of Stack Token to TopUp the account with
     * @param Cluster DNS where the balance will be added to.
     */
    function rechargeAccount(uint256 amount, bytes32 clusterDns) public {
        _rechargeAccountInternal(amount, msg.sender, clusterDns, true, false);
    }

    /*
     * @title Withdraw user total deposited Funds & settles his pending balances
     */
    function withdrawFunds(bytes32 clusterDns) public {
        _settleAndWithdraw(msg.sender, clusterDns, 0, true);
    }

    /*
     * @title Set portion and token that will be recived when settelment happens that is not stack.
     * @param Address of Token user wants to receive.
     * @param Porton of token in relation to stack in %
     */

    function setWithdrawTokenPortion(address token, uint256 percent) public {
        require(percent <= 10000, "Has to be below 10000");
        WithdrawSetting storage withdrawsetup = withdrawSettings[msg.sender];
        withdrawsetup.token = token;
        withdrawsetup.percent = percent;
    }

    /*
     * @title Withdraw user deposited Funds partially
     * @param Amount of Stack Token user wants to withdraw
     * @param Cluster DNS where the withdraw should be done from
     */
    function withdrawFundsPartial(uint256 amount, bytes32 clusterDns) public {
        _settleAndWithdraw(msg.sender, clusterDns, amount, false);
    }

    /*
     * @title Contrubute Stack tokens for issuing grants
     * @param Amount of Stack
     */

    function communityDeposit(uint256 amount) public {
        _pullStackTokens(amount);
        communityDeposits = communityDeposits.add(amount);
    }

    /*
     * @title Issuing a grant to a new account
     * @param address of grant reciever
     * @param Amount of Stack issued as grant
     * @param Resources being boight. A list of 8 item. List of available resources and their order -> resourceVar(id) (1-8)
     */

    function issueGrantNewAccount(
        address developer,
        uint256 amount,
        bytes32 clusterDns,
        ResourceUnits memory resourceUnits
    ) public onlyOwner {
        require(amount <= communityDeposits, "Over deposit limit");
        Deposit storage deposit = deposits[developer][clusterDns];
        require(deposit.lastTxTime == 0);
        require(deposit.totalDeposit == 0);
        require(amount > 0);
        communityDeposits = communityDeposits - amount;
        _createDepositInternal(
            clusterDns,
            resourceUnits,
            amount,
            developer,
            false,
            true
        );
    }

    /*
     * @title Issue a grant to an existing account.
     * @param Address of grant reciever
     * @param Amount of Stack issued as grant
     * @param ClusterDNS
     */

    function issueGrantRechargeAccount(
        address developer,
        uint256 amount,
        bytes32 clusterDns
    ) public onlyOwner {
        require(amount <= communityDeposits, "Over available");
        communityDeposits = communityDeposits - amount;
        _rechargeAccountInternal(amount, developer, clusterDns, false, true);
    }
}
