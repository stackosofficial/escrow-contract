pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

library EscrowLib {
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

    // Address of Token contract.
    // What percentage is exchanged to this token on withdrawl.
    struct WithdrawSetting {
        address token;
        uint256 percent;
    }

    struct ResourceUnits {
        uint256 resourceOne; // cpuCoresUnits
        uint256 resourceTwo; // diskSpaceUnits
        uint256 resourceThree; // bandwidthUnits
        uint256 resourceFour; // memoryUnits
        uint256 resourceFive;
        uint256 resourceSix;
        uint256 resourceSeven;
        uint256 resourceEight;
    }


}
