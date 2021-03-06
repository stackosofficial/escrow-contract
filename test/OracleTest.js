const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const OracleFeed = artifacts.require("StackOracle");

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

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
      await oracleFeed.usdtToSTACKOracle("1000000").then(function (c) {
        var PriceUSDT = c.toString();
        console.log(PriceUSDT);
      });
    });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
