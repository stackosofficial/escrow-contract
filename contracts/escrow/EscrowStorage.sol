pragma solidity ^0.6.12;
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./EscrowLib.sol";

contract EscrowStorage {
    address internal stackToken;
    address public resourceFeed;
    address public staking;
    address public dao;
    address public gov;
    uint256 public govFee;
    uint256 public daoFee;
    uint256 public communityDeposits;
    address public dnsStore;
    IUniswapV2Factory internal factory;
    IUniswapV2Router02 internal router;
    address internal weth;
    address internal usdt;
    address internal oracle;
    uint256 internal minPurchase;

    mapping(uint16 => string) internal resourceVar;
    mapping(bytes32 => EscrowLib.ResourceUnits) public resourceCapacityState;
    mapping(string => EscrowLib.ResourceFees) public fixedResourceFee;
    mapping(address => EscrowLib.WithdrawSetting) internal withdrawSettings;
    mapping(address => mapping(bytes32 => EscrowLib.Deposit)) internal deposits;
    mapping(bytes32 => address[]) public clusterUsers;
}
