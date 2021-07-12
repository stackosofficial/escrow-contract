pragma solidity ^0.6.12;
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";

contract EscrowStorage {
    address public stackToken;
    address public resourceFeed;
    address public staking;
    uint256 public ethEarned;
    uint256 public stackEarned;
    uint256 public dripRatePerSecond;
    address public dao;
    address public gov;
    uint256 public govFee;
    uint256 public daoFee;
    uint256 internal EXP = 10**18;
    address public dnsStore;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address public weth;
    address public usdt;

    struct ResourceFees {
        uint256 cpuFee;
        uint256 diskFee;
        uint256 bandwidthFee;
        uint256 memoryFee;
    }

    // Address of Token contract.
    // What percentage is exchanged to this token on withdrawl.
    struct WithdrawSetting {
        address token;
        uint256 percent;
    }

    struct Deposit {
        uint256 cpuCoresUnits;
        uint256 diskSpaceUnits;
        uint256 bandwidthUnits;
        uint256 memoryUnits;
        uint256 totalDeposit;
        uint256 lastTxTime;
        bool isStackToken;
        uint256 totalDripRatePerSecond;
    }

    mapping(string => ResourceFees) public fixedResourceFee;
    mapping(address => WithdrawSetting) public withdrawsettings;
    mapping(address => mapping(bytes32 => Deposit)) public deposits;
}
