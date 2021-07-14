const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const StackEscrow = artifacts.require("StackEscrow");
const ResourceFeed = artifacts.require("ResourceFeed");
const StackToken = artifacts.require("StackToken");
const DNSCluster = artifacts.require("DnsClusterMetadataStore");
const IERC20 = artifacts.require("IERC20");
const UniswapV2Router = artifacts.require("IUniswapV2Router02");

const _stackosControllerAdress = "0x77c940F10a7765B49273418aDF5750979718e85f";
const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const resourceFeedAddress = "0x0d8031E976f1df6Af6Dac52A91dE255c8CBCfc08";
const stakingContractAddress = "0x7d2f88933e52C352549c748BB572F3c383528fF2";
const StackTokenMainNet = "0x56A86d648c435DC707c8405B78e2Ae8eB4E60Ba4";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const clusterDns =
  "0x74657374646e7300000000000000000000000000000000000000000000000000";

contract("StackEscrow", (accounts) => {
  describe("Contract Deployment", async () => {
    it("Deploying ResourceFeed", async () => {
      resourceFeed = await ResourceFeed.new(StackTokenMainNet, WETH);
      assert.equal((await resourceFeed.address) !== "", true);
      stackToken = await IERC20.at(StackTokenMainNet);
    });

    it("Deploying DnsClusterMetadataStore", async () => {
      dnsCluster = await DNSCluster.new(resourceFeed.address);
      assert.equal((await dnsCluster.address) !== "", true);

      await resourceFeed.setclusterMetadataStore(dnsCluster.address);
    });

    it("StackEscrow Contract Has been deployed", async () => {
      stackEscrow = await StackEscrow.new(
        StackTokenMainNet,
        resourceFeed.address,
        stakingContractAddress,
        dnsCluster.address,
        UniswapV2FactoryAddress,
        UniswapV2RouterAddress,
        _stackosControllerAdress,
        _stackosControllerAdress,
        WETH,
        USDT
      );
      assert.equal((await stackEscrow.address) !== "", true);
    });

    it("Set Fixed Resource fees.", async () => {
      await stackEscrow.setFixedFees("dao", "10", "10", "10", "10");
      await stackEscrow.setFixedFees("gov", "10", "10", "10", "10");

      await stackEscrow.fixedResourceFee("dao").then(function (c) {
        var daoCpuFee = c["cpuFee"].toString();
        var daoDiskFee = c["diskFee"].toString();
        var daoBandwidthFee = c["bandwidthFee"].toString();
        var daoMemoryFee = c["memoryFee"].toString();

        assert.equal(daoCpuFee == "10", true);
        assert.equal(daoDiskFee == "10", true);
        assert.equal(daoBandwidthFee == "10", true);
        assert.equal(daoMemoryFee == "10", true);
      });
      await stackEscrow.fixedResourceFee("gov").then(function (c) {
        var govCpuFee = c["cpuFee"].toString();
        var govDiskFee = c["diskFee"].toString();
        var govBandwidthFee = c["bandwidthFee"].toString();
        var govMemoryFee = c["memoryFee"].toString();

        assert.equal(govCpuFee == "10", true);
        assert.equal(govDiskFee == "10", true);
        assert.equal(govBandwidthFee == "10", true);
        assert.equal(govMemoryFee == "10", true);
      });
    });
  });

  // In the future you need to connect it to the staking contract.

  describe("Set staking Contract. (Temp for testing.)", async () => {
    it("setStakingContract()", async () => {
      await dnsCluster.setStakingContract(accounts[0]);
      assert.equal(
        (await dnsCluster.stakingContract.call()) == accounts[0],
        true
      );
    });
  });

  describe("1. Provider creates a cluster, resource & set's price.", async () => {
    it("addDnsToClusterEntry()", async () => {
      await dnsCluster.addDnsToClusterEntry(
        clusterDns,
        accounts[1],
        "120.231.231.21",
        "120.231.231.21"
      );
      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var clusterOwner = c["clusterOwner"];
        assert.equal(clusterOwner == accounts[1], true);
      });
    });

    it("addResource()", async () => {
      await resourceFeed.addResource(
        clusterDns,
        "cpu",
        // pricePerUnit
        "8333333000000000",
        // dripRatePerUnit
        "3215020447",
        { from: accounts[1] }
      );
      await resourceFeed.resources(clusterDns, "cpu").then(function (c) {
        var resourceName = c["name"];
        var pricePerUnit = c["pricePerUnit"];
        var dripRatePerUnit = c["dripRatePerUnit"];
        var votingWeightPerUnit = c["votingWeightPerUnit"];

        assert.equal(resourceName == "cpu", true);
        assert.equal(pricePerUnit == "8333333000000000", true);
        assert.equal(dripRatePerUnit == "3215020447", true);
        assert.equal(votingWeightPerUnit == "0", true);
      });
    });
  });

  describe("2. Developer purchases resources.", async () => {
    it("Buy Stack Tokens from Uniswap", async () => {
      const uniswapV2Router = await UniswapV2Router.at(UniswapV2RouterAddress);
      var amountOutMin = 0;
      var path = [WETH, StackTokenMainNet];
      var deadline = Math.floor(Date.now() / 1000) + 1200;
      var amount = "100000000000000000";

      await uniswapV2Router.swapExactETHForTokens(
        amountOutMin,
        path,
        accounts[4],
        deadline,
        { value: amount, from: accounts[4] }
      );

      await stackToken
        .balanceOf(accounts[4])
        .then((c) => console.log(c.toString()));
    });

    it("Approve Escrow to spend on my behalf.", async () => {
      await stackToken.approve(stackEscrow.address, "90000000000000000000", {
        from: accounts[4],
      });
    });

    it("updateResourcesByStackAmount()", async () => {
      await stackEscrow.updateResourcesByStackAmount(
        clusterDns,
        // CPU
        1,
        // DiskStorage
        1,
        // Bandwith
        1,
        // Memory
        1,
        // Deposit Amount
        "10000000000000000000",
        {
          from: accounts[4],
        }
      );
      await stackEscrow.deposits(accounts[4], clusterDns).then(function (c) {
        var amount = c["totalDeposit"].toString();
        assert.equal(amount == "10000000000000000000", true);
      });
    });

    it("Get Drip Rate in USD.", async () => {
      await stackEscrow
        .getResourcesDripRateInUSDT(clusterDns, 1, 1, 1, 1)
        .then((c) => console.log(c.toString()));
    });

    it("Taking a Snapshot Before Time Testing.", async () => {
      snapshot = await timeMachine.takeSnapshot();
      snapshotId = snapshot["result"];
    });

    it("SettleAccounts()", async () => {
      await stackEscrow.timenow().then((c) => console.log(c.toString()));
      await timeMachine.advanceTimeAndBlock(60 * 60 * 48);
      await stackEscrow.timenow().then((c) => console.log(c.toString()));
      assert.equal((await stackToken.balanceOf(accounts[1])) == "0", true);
      await stackEscrow.settleAccounts(accounts[4], clusterDns);

      await stackToken
        .balanceOf(accounts[1])
        .then((c) => console.log(c.toString()));
    });

    it("setWithdrawTokenPortion()", async () => {
      await stackEscrow.setWithdrawTokenPortion(USDT, 5000, {
        from: accounts[1],
      });
      await stackEscrow.withdrawSettings(accounts[1]).then(function (c) {
        var address = c["token"].toString();
        var percent = c["percent"].toString();

        assert.equal(address == USDT, true);
        assert.equal(percent == "5000", true);
      });
    });

    it("updateResourcesByStackAmount()", async () => {
      await stackEscrow.updateResourcesByStackAmount(
        clusterDns,
        // CPU
        1,
        // DiskStorage
        1,
        // Bandwith
        1,
        // Memory
        1,
        // Deposit Amount
        "10000000000000000000",
        {
          from: accounts[4],
        }
      );
      await stackEscrow.deposits(accounts[4], clusterDns).then(function (c) {
        var amount = c["totalDeposit"].toString();
        assert.equal(amount == "10000000000000000000", true);
      });
    });

    it("SettleAccounts()", async () => {
      await stackEscrow.timenow().then((c) => console.log(c.toString()));
      await timeMachine.advanceTimeAndBlock(60 * 60 * 48);
      await stackEscrow.timenow().then((c) => console.log(c.toString()));
      // assert.equal((await stackToken.balanceOf(accounts[1])) == "0", true);

      await stackToken
        .balanceOf(stackEscrow.address)
        .then((c) => console.log(c.toString()));

      await stackEscrow.settleAccounts(accounts[4], clusterDns);

      await stackToken
        .balanceOf(accounts[1])
        .then((c) => console.log(c.toString()));
    });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
