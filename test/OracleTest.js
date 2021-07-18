const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const OracleFeed = artifacts.require("StackOracle");

const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

contract("StackOracle", (accounts) => {
  describe("Contract Deployment", async () => {
    it("Oracle Contract Has been deployed", async () => {
      snapshot = await timeMachine.takeSnapshot();
      snapshotId = snapshot["result"];
      oracleFeed = await OracleFeed.new(lpstack, lpusdt);
    });

    it("Update and roll time.", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 24);
      await oracleFeed.update();
    });

    it("Get price", async () => {
      await oracleFeed.consult("1000000000").then(function (c) {
        var PriceUSDT = c.toString();
        console.log(PriceUSDT);
      });
    });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
