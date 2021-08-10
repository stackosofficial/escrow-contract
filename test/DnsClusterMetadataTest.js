const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const StackEscrow = artifacts.require("StackEscrow");
const ResourceFeed = artifacts.require("ResourceFeed");
const DNSCluster = artifacts.require("DnsClusterMetadataStore");
const IERC20 = artifacts.require("IERC20");
const UniswapV2Router = artifacts.require("IUniswapV2Router02");

const UniswapV2FactoryAddress = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
const UniswapV2RouterAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
const stakingContractAddress = "0x7d2f88933e52C352549c748BB572F3c383528fF2";
const StackTokenMainNet = "0x6855f7bb6287F94ddcC8915E37e73a3c9fEe5CF3";
const WETH = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const USDT = "0x55d398326f99059fF775485246999027B3197955";
const clusterDns =
  "0x74657374646e7300000000000000000000000000000000000000000000000000";
const OracleFeed = artifacts.require("StackOracle");

const lpstack = "0x17e9216402138B15B30bd341c0377054e42aEbf8";
const lpusdt = "0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE";

contract("StackEscrow", (accounts) => {
  clusterProviderWallet = accounts[1];
  developerWallet = accounts[4];
  developerWallet2 = accounts[5];
  developerWallet3 = accounts[6];
  daoAddress = accounts[9];
  govAddress = accounts[8];

  describe("Contract Deployment", async () => {
    it("ResourceFeed Contract Has been deployed", async () => {
      resourceFeed = await ResourceFeed.new(StackTokenMainNet);
      assert.equal((await resourceFeed.address) !== "", true);
      stackToken = await IERC20.at(StackTokenMainNet);
      usdtToken = await IERC20.at(USDT);
    });

    it("DnsClusterMetadataStore Contract Has been deployed", async () => {
      dnsCluster = await DNSCluster.new(resourceFeed.address);
      assert.equal((await dnsCluster.address) !== "", true);
    });

    it("Oracle Contract Has been deployed", async () => {
      oracleFeed = await OracleFeed.new(lpstack, lpusdt, WETH);
    });

    it("StackEscrow Contract Has been deployed", async () => {
      stackEscrow = await StackEscrow.new(
        StackTokenMainNet,
        resourceFeed.address,
        stakingContractAddress,
        dnsCluster.address,
        UniswapV2FactoryAddress,
        UniswapV2RouterAddress,
        daoAddress,
        govAddress,
        WETH,
        USDT,
        oracleFeed.address
      );
      assert.equal((await stackEscrow.address) !== "", true);
    });

    it("Set up ResourceFeed Contract", async () => {
      await resourceFeed.setAddressSetting(
        dnsCluster.address,
        stackEscrow.address
      );
    });
  });

  describe("Define Resources", async () => {
    it("Define Resources.", async () => {
      await stackEscrow.defineResourceVar(1, "cpuMillicore");
      await stackEscrow.defineResourceVar(2, "diskSpaceGB");
      await stackEscrow.defineResourceVar(3, "requestPerSecond");
      await stackEscrow.defineResourceVar(4, "memoryMB");
      await stackEscrow.defineResourceVar(5, "undefined");
      await stackEscrow.defineResourceVar(6, "undefined");
      await stackEscrow.defineResourceVar(7, "undefined");
      await stackEscrow.defineResourceVar(8, "undefined");
    });
  });

  describe("Setting platform fees", async () => {
    it("Set Variable Resource fees.", async () => {
      // 1%
      await stackEscrow.setVariableFees("0", "0");

      await stackEscrow.daoFee.call().then(function (c) {
        var daoFee = c.toString();
        assert.equal(daoFee == "0", true);
      });
      await stackEscrow.govFee.call().then(function (c) {
        var govFee = c.toString();
        assert.equal(govFee == "0", true);
      });
    });
  });

  describe("Set staking Contract. (Temp for testing.)", async () => {
    it("setAddressSetting()", async () => {
      await dnsCluster.setAddressSetting(accounts[0], stackEscrow.address);
      assert.equal(
        (await dnsCluster.stakingContract.call()) == accounts[0],
        true
      );
    });
  });

  describe("1. Provider creates a cluster", async () => {
    it("addDnsToClusterEntry()", async () => {
      await dnsCluster.addDnsToClusterEntry(
        clusterDns,
        clusterProviderWallet,
        "120.231.231.21",
        "120.231.231.21",
        "Hi",
        false
      );
      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var clusterOwner = c["clusterOwner"];
        assert.equal(clusterOwner == clusterProviderWallet, true);
      });
    });

    it("try addDnsToClusterEntry() using the same DNS and fail", async () => {
      try {
        await dnsCluster.addDnsToClusterEntry(
          clusterDns,
          clusterProviderWallet,
          "120.231.231.21",
          "120.231.231.21",
          "Hi",
          false
        );
        assert.fail("This transaction should have thrown an error.");
      } catch (err) {
        assert.include(err.message, "revert");
      }
    });
  });

  describe("1. Provider creates a cluster", async () => {
    it("addResource()", async () => {
      await resourceFeed.addResource(
        clusterDns,
        1, // cpuMillicore
        // dripRatePerUnit
        "772090000000000",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        2, // diskSpaceGB
        // dripRatePerUnit
        "1984",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        3, // requestPerSecond
        // dripRatePerUnit
        "1984",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        4, // memoryMB
        // dripRatePerUnit
        "1984",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        5, // Undefined
        // dripRatePerUnit
        "0",
        { from: clusterProviderWallet }
      );
      await resourceFeed.addResource(
        clusterDns,
        6, // Undefined
        // dripRatePerUnit
        "0",
        { from: clusterProviderWallet }
      );
      await resourceFeed.addResource(
        clusterDns,
        7, // Undefined
        // dripRatePerUnit
        "0",
        { from: clusterProviderWallet }
      );
      await resourceFeed.addResource(
        clusterDns,
        8, // Undefined
        // dripRatePerUnit
        "0",
        { from: clusterProviderWallet }
      );

      await resourceFeed
        .resources(clusterDns, "cpuMillicore")
        .then(function (c) {
          var resourceName = c["name"];
          var dripRatePerUnit = c["dripRatePerUnit"];
          var votingWeightPerUnit = c["votingWeightPerUnit"];

          assert.equal(resourceName == "cpuMillicore", true);
          assert.equal(dripRatePerUnit == "772090000000000", true);
          assert.equal(votingWeightPerUnit == "0", true);
        });
    });

    it("setResourceMaxCapacity()", async () => {
      await resourceFeed.setResourceMaxCapacity(
        clusterDns,
        [10, 10, 10, 10, 0, 0, 0, 0],
        { from: clusterProviderWallet }
      );

      await resourceFeed.resourcesMaxPerDNS(clusterDns).then(function (c) {
        var resourceOneUnits = c["resourceOne"];
        var resourceTwoUnits = c["resourceTwo"];
        var resourceThreeUnits = c["resourceThree"];
        var resourceFourUnits = c["resourceFour"];
        var resourceFiveUnits = c["resourceFive"];
        var resourceSixUnits = c["resourceSix"];

        assert.equal(resourceOneUnits == "10", true);
        assert.equal(resourceTwoUnits == "10", true);
        assert.equal(resourceThreeUnits == "10", true);
        assert.equal(resourceFourUnits == "10", true);
        assert.equal(resourceFiveUnits == "0", true);
        assert.equal(resourceSixUnits == "0", true);
      });
    });
  });

  describe("Changes cluster status", async () => {
    it("addDnsToClusterEntry()", async () => {
      await dnsCluster.changeClusterStatus(clusterDns, false, {
        from: clusterProviderWallet,
      });
      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var isActive = c["active"];
        assert.equal(isActive == false, true);
      });

      await dnsCluster.changeClusterStatus(clusterDns, true, {
        from: clusterProviderWallet,
      });
      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var isActive = c["active"];
        assert.equal(isActive == true, true);
      });
    });
  });

  describe("Add Resource Weights", async () => {
    it("setResourceVotingWeight()", async () => {
      await resourceFeed.setResourceVotingWeight(
        clusterDns,
        "cpuMillicore",
        5,
        { from: accounts[0] }
      );
      await resourceFeed.setResourceVotingWeight(clusterDns, "diskSpaceGB", 5, {
        from: accounts[0],
      });
      await resourceFeed.setResourceVotingWeight(
        clusterDns,
        "requestPerSecond",
        5,
        { from: accounts[0] }
      );
      await resourceFeed.setResourceVotingWeight(clusterDns, "memoryMB", 5, {
        from: accounts[0],
      });

      await resourceFeed.setResourceVotingWeight(clusterDns, "undefined", 0, {
        from: accounts[0],
      });

      await resourceFeed
        .getResourceVotingWeight(clusterDns, "cpuMillicore")
        .then(function (c) {
          var voteWeight = c;
          console.log(voteWeight.toString());
          assert.equal(voteWeight == 5, true);
        });
    });
  });

  describe("Add Resource Weights", async () => {
    it("setResourceVotingWeight()", async () => {
      await resourceFeed.setResourceVotingWeight(
        clusterDns,
        "cpuMillicore",
        5,
        { from: accounts[0] }
      );
      await resourceFeed.setResourceVotingWeight(clusterDns, "diskSpaceGB", 5, {
        from: accounts[0],
      });
      await resourceFeed.setResourceVotingWeight(
        clusterDns,
        "requestPerSecond",
        5,
        { from: accounts[0] }
      );
      await resourceFeed.setResourceVotingWeight(clusterDns, "memoryMB", 5, {
        from: accounts[0],
      });

      await resourceFeed.setResourceVotingWeight(clusterDns, "undefined", 0, {
        from: accounts[0],
      });

      await resourceFeed
        .getResourceVotingWeight(clusterDns, "cpuMillicore")
        .then(function (c) {
          var voteWeight = c;
          console.log(voteWeight.toString());
          assert.equal(voteWeight == 5, true);
        });
    });
  });

  describe("2. Developer buys STACK Tokens from Uni", async () => {
    it("Buy Stack Tokens from Uniswap", async () => {
      const uniswapV2Router = await UniswapV2Router.at(UniswapV2RouterAddress);
      var amountOutMin = 0;
      var path = [WETH, StackTokenMainNet];
      var deadline = Math.floor(Date.now() / 1000) + 1200;
      // 1 Eth
      var amount = "1000000000000000000";

      await uniswapV2Router.swapExactETHForTokens(
        amountOutMin,
        path,
        developerWallet,
        deadline,
        { value: amount, from: developerWallet }
      );

      await stackToken
        .balanceOf(developerWallet)
        .then((c) => console.log("Balance of STACK TOKENS: " + c.toString()));

      await stackToken.transfer(developerWallet2, "1615000000000000000000", {
        from: developerWallet,
      });
      await stackToken.transfer(developerWallet3, "1615000000000000000000", {
        from: developerWallet,
      });
    });
  });

  describe("2. Developer purchases resources.", async () => {
    it("Approve Escrow to spend on my behalf.", async () => {
      await stackToken.approve(
        stackEscrow.address,
        "900000000000000000000000000",
        {
          from: developerWallet,
        }
      );

      await stackToken.approve(
        stackEscrow.address,
        "900000000000000000000000000",
        {
          from: developerWallet2,
        }
      );
      await stackToken.approve(
        stackEscrow.address,
        "900000000000000000000000000",
        {
          from: developerWallet3,
        }
      );
    });

    it("Taking a Snapshot Before Time Testing.", async () => {
      snapshot = await timeMachine.takeSnapshot();
      snapshotId = snapshot["result"];
    });

    it("Update and roll time.", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 24);
      await oracleFeed.update();
    });

    it("updateResourcesFromStack()", async () => {
      await stackEscrow.updateResourcesFromStack(
        clusterDns,
        [1, 0, 0, 0, 0, 0, 0, 0],
        "20000000000000000000",
        {
          from: developerWallet,
        }
      );
      await stackEscrow
        .getDeposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "20000000000000000000", true);
        });
    });
  });

  describe("upvote a cluster", async () => {
    it("upvoteCluster()", async () => {
      await dnsCluster
        .getTotalVotes(1, 1, 1, 1, 1, 1, 1, 1, clusterDns)
        .then(function (c) {
          var votes = c.toString();
          console.log(votes);
        });
    });

    it("upvoteCluster()", async () => {
      await dnsCluster.upvoteCluster(clusterDns, {
        from: developerWallet,
      });

      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var upvotes = c["upvotes"];
        console.log(upvotes.toString());
        assert.equal(upvotes == 1, true);
      });
    });

    it("downvoteCluster()", async () => {
      await dnsCluster.downvoteCluster(clusterDns, {
        from: developerWallet,
      });

      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var upvotes = c["upvotes"];
        var downvotes = c["downvotes"];
        console.log(upvotes.toString());
        console.log(downvotes.toString());
        assert.equal(downvotes == 1, true);
      });
    });
  });
});
