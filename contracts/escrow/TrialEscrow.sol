// pragma solidity ^0.6.0;

// import "./BaseEscrow.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// contract TrialEscrow is Ownable {
//     address public resourcePriceFeed;

//     event TRIALDEPOSIT(
//         address indexed owner,
//         uint256 totalDeposit,
//         uint256 lockedAt,
//         uint256 indexed dripRate
//     );

//     event TRIALWITHDRAW(address indexed owner);

//     struct Deposit {
//         uint256 cpuCoresUnits;
//         uint256 diskSpaceUnits;
//         uint256 bandwidthUnits;
//         uint256 memoryUnits;
//         uint256 totalDeposit;
//         uint256 lockedAt;
//         bool isStackToken;
//         uint256 totalDripRatePerSecond;
//     }

//     mapping(address => Deposit) public deposits;

//     constructor(address _priceFeed) public {
//         resourcePriceFeed = _priceFeed;
//     }

//     function updateResourcesByAmount(
//         uint256 cpuCoresUnits,
//         uint256 diskSpaceUnits,
//         uint256 bandwidthUnits,
//         uint256 memoryUnits,
//         uint256 depositAmount,
//         address depositer
//     ) public onlyOwner {
//         Deposit storage deposit = deposits[depositer];
//         require(
//             deposit.lockedAt == 0,
//             "Deposit already exists for this address"
//         );
//         require(deposit.totalDeposit == 0, "Non zero amount already deposited");
//         require(depositAmount > 0, "zero deposit amount");
//         require(depositer != address(0), "invalid depositer address");

//         deposit.lockedAt = block.timestamp;
//         deposit.isStackToken = true;
//         deposit.cpuCoresUnits = cpuCoresUnits;
//         deposit.diskSpaceUnits = diskSpaceUnits;
//         deposit.bandwidthUnits = bandwidthUnits;
//         deposit.memoryUnits = memoryUnits;
//         deposit.totalDeposit = depositAmount;

//         deposit.totalDripRatePerSecond =
//             _calcResourceUnitsDripRate("cpu", deposit.cpuCoresUnits, true) +
//             _calcResourceUnitsDripRate("memory", deposit.memoryUnits, true) +
//             _calcResourceUnitsDripRate("disk", deposit.diskSpaceUnits, true) +
//             _calcResourceUnitsDripRate(
//                 "bandwidth",
//                 deposit.bandwidthUnits,
//                 true
//             );

//         emit TRIALDEPOSIT(
//             depositer,
//             deposit.totalDeposit,
//             deposit.lockedAt,
//             deposit.totalDripRatePerSecond
//         );
//     }

//     function withdrawFunds(address depositer) public payable onlyOwner {
//         require(depositer != address(0), "invalid depositor address");

//         Deposit storage deposit = deposits[depositer];

//         require(deposit.totalDeposit > 0, "no active deposit");

//         delete deposits[depositer];

//         emit TRIALWITHDRAW(depositer);
//     }

//     function _calcResourceUnitsDripRate(
//         string memory resourceName,
//         uint256 resourceUnits,
//         bool isStackToken
//     ) internal view returns (uint256) {
//         uint256 dripRatePerUnit =
//             IResourceFeed(resourcePriceFeed).getResourceDripRate(resourceName);
//         uint256 unitConverter = 1;
//         if (isStackToken == true) {
//             unitConverter = IResourceFeed(resourcePriceFeed)
//                 .STACK_TOKENS_PER_USD();
//         }
//         return dripRatePerUnit * resourceUnits * unitConverter;
//     }
// }
