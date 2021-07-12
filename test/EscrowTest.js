const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const StackEscrow = artifacts.require("StackEscrow");
const ResourceFeed = artifacts.require("ResourceFeed");
const StackToken = artifacts.require("StackToken");
const DNSCluster = artifacts.require("DnsClusterMetadataStore");
const IERC20 = artifacts.require("IERC20");

const _stackosControllerAdress = "0x77c940F10a7765B49273418aDF5750979718e85f";
const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const StackTokenMainNet = "0x56A86d648c435DC707c8405B78e2Ae8eB4E60Ba4";
// const usdtTokenAddress = "0x1F78EE1aE16479717477F418A05e9148e4A59f10";
const resourceFeedAddress = "0x0d8031E976f1df6Af6Dac52A91dE255c8CBCfc08";
const stakingContractAddress = "0x7d2f88933e52C352549c748BB572F3c383528fF2";
const WETH = "0xd0A1E359811322d97991E03f863a0C30C2cF029C";
const USDT = "0xdac17f958d2ee523a2206206994597c13d831ec7";
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
        // votingWeightPerUnit
        "1000000000000000",
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
        assert.equal(votingWeightPerUnit == "1000000000000000", true);
      });
    });
  });

  describe("2. Developer purchases resources.", async () => {
    it("Approve Escrow to spend on my behalf.", async () => {
      stackToken.approve(stackEscrow.address, 100000000000);
    });

    // it("updateResourcesByStackAmount()", async () => {
    //   await stackEscrow.updateResourcesByStackAmount(
    //     clusterDns,
    //     // CPU
    //     1,
    //     // DiskStorage
    //     1,
    //     // Bandwith
    //     1,
    //     // Memory
    //     1,
    //     // Deposit Amount
    //     20000000000
    //   );
    //   await stackEscrow.deposits(accounts[0], clusterDns).then(function (c) {
    //     var amount = c["totalDeposit"].toString();
    //     assert.equal(amount == "20000000000", true);
    //   });
    // });

    it("Get Drip Rate in USD.", async () => {
      await stackEscrow
        .getResourcesDripRate(clusterDns, 1, 1, 1, 1)
        .then((c) => console.log(c.toString()));
    });

    // it("SettleAccounts()", async () => {
    //   await timeMachine.advanceTimeAndBlock(60 * 60 * 24);

    //   assert.equal((await stackToken.balanceOf(accounts[1])) == "0", true);
    //   await stackEscrow.settleAccounts(accounts[0], clusterDns);
    //   assert.equal(
    //     (await stackToken.balanceOf(accounts[1])) == "19993088000",
    //     true
    //   );
    // });

    it("setWithdrawTokenPortion()", async () => {
      await stackEscrow.setWithdrawTokenPortion(StackTokenMainNet, 5000);
      await stackEscrow.withdrawsettings(accounts[0]).then(function (c) {
        var address = c["token"].toString();
        var percent = c["percent"].toString();

        assert.equal(address == StackTokenMainNet, true);
        assert.equal(percent == "5000", true);
      });
    });
  });
});
