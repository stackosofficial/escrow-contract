pragma solidity ^0.6.12;
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";
import "./EscrowLib.sol";

contract EscrowStorage {
    address internal stackToken;
    address internal resourceFeed;
    address internal staking;
    address public dao;
    address public gov;
    uint8 public govFee;
    uint8 public daoFee;
    uint256 public communityDeposits;
    address internal dnsStore;
    IUniswapV2Factory internal factory;
    IUniswapV2Router02 internal router;
    address internal weth;
    address internal usdt;
    address internal oracle;
    uint256 internal minPurchase;

    mapping(uint8 => string) internal resourceVar;
    mapping(address => EscrowLib.WithdrawSetting) internal withdrawSettings;
    mapping(address => mapping(bytes32 => EscrowLib.Deposit)) internal deposits;
    mapping(bytes32 => EscrowLib.ResourceUnits) public resourceCapacityState;
    mapping(bytes32 => address[]) public clusterUsers;
}
