const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const OracleFeed = artifacts.require("StackOracle");

const WETH = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const lpstack = "0x17e9216402138B15B30bd341c0377054e42aEbf8";
const lpusdt = "0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE";

contract("StackOracle", (accounts) => {
  describe("Contract Deployment", async () => {
    it("Oracle Contract Has been deployed", async () => {
      snapshot = await timeMachine.takeSnapshot();
      snapshotId = snapshot["result"];
      oracleFeed = await OracleFeed.new(lpstack, lpusdt, WETH);
    });

    it("Update and roll time.", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 24);
      await oracleFeed.update();
    });

    it("USDT address", async () => {
      await oracleFeed.USDT.call().then(function (c) {
        var USDTadr = c.toString();
        console.log(USDTadr);
      });
    });

    it("GET ETH address", async () => {
      await oracleFeed.STACK.call().then(function (c) {
        var STACKadr = c.toString();
        console.log(STACKadr);
      });
    });

    it("Get price", async () => {
      await oracleFeed
        .usdtToSTACKOracle("1000000000000000000")
        .then(function (c) {
          var PriceUSDT = c.toString();
          console.log(PriceUSDT);
        });
    });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
