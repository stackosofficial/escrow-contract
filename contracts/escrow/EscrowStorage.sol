pragma solidity ^0.6.12;
import "./uniswap/IUniswapV2Factory.sol";
import "./uniswap/IUniswapV2Router02.sol";

contract EscrowStorage {
    address public stackToken;
    address public resourceFeed;
    address public staking;
    address public dao;
    address public gov;
    uint256 public govFee;
    uint256 public daoFee;
    uint256 public communityDeposits;
    address public dnsStore;
    IUniswapV2Factory public factory;
    IUniswapV2Router02 public router;
    address internal weth;
    address internal usdt;
    address internal oracle;

    struct ResourceFees {
        uint256 resourceOneUnitsFee; // cpuCoresUnits
        uint256 resourceTwoUnitsFee; // diskSpaceUnits
        uint256 resourceThreeUnitsFee; // bandwidthUnits
        uint256 resourceFourUnitsFee; // memoryUnits
        uint256 resourceFiveUnitsFee;
        uint256 resourceSixUnitsFee;
        uint256 resourceSevenUnitsFee;
        uint256 resourceEightUnitsFee;
    }

    // Address of Token contract.
    // What percentage is exchanged to this token on withdrawl.
    struct WithdrawSetting {
        address token;
        uint256 percent;
    }

    struct ResourceUnits {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
    }

    struct Deposit {
        uint256 resourceOneUnits; // cpuCoresUnits
        uint256 resourceTwoUnits; // diskSpaceUnits
        uint256 resourceThreeUnits; // bandwidthUnits
        uint256 resourceFourUnits; // memoryUnits
        uint256 resourceFiveUnits;
        uint256 resourceSixUnits;
        uint256 resourceSevenUnits;
        uint256 resourceEightUnits;
        uint256 totalDeposit;
        uint256 lastTxTime;
        uint256 totalDripRatePerSecond;
        uint256 notWithdrawable;
    }

    mapping(uint16 => string) public resourceVar;
    mapping(string => ResourceFees) public fixedResourceFee;
    mapping(address => WithdrawSetting) public withdrawSettings;
    mapping(address => mapping(bytes32 => Deposit)) public deposits;
    mapping(bytes32 => address[]) public clusterUsers;
}
