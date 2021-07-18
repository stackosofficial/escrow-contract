const { assert } = require("chai");
const timeMachine = require("ganache-time-traveler");

const StackEscrow = artifacts.require("StackEscrow");
const ResourceFeed = artifacts.require("ResourceFeed");
const DNSCluster = artifacts.require("DnsClusterMetadataStore");
const IERC20 = artifacts.require("IERC20");
const UniswapV2Router = artifacts.require("IUniswapV2Router02");

const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const stakingContractAddress = "0x7d2f88933e52C352549c748BB572F3c383528fF2";
const StackTokenMainNet = "0x56A86d648c435DC707c8405B78e2Ae8eB4E60Ba4";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const clusterDns =
  "0x74657374646e7300000000000000000000000000000000000000000000000000";
const OracleFeed = artifacts.require("StackOracle");

const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

contract("StackEscrow", (accounts) => {
  describe("Contract Deployment", async () => {
    it("ResourceFeed Contract Has been deployed", async () => {
      resourceFeed = await ResourceFeed.new(StackTokenMainNet, WETH);
      assert.equal((await resourceFeed.address) !== "", true);
      stackToken = await IERC20.at(StackTokenMainNet);
      usdtToken = await IERC20.at(USDT);
    });

    it("DnsClusterMetadataStore Contract Has been deployed", async () => {
      dnsCluster = await DNSCluster.new(resourceFeed.address);
      assert.equal((await dnsCluster.address) !== "", true);
      await resourceFeed.setclusterMetadataStore(dnsCluster.address);
    });

    it("Oracle Contract Has been deployed", async () => {
      oracleFeed = await OracleFeed.new(lpstack, lpusdt);
    });

    it("StackEscrow Contract Has been deployed", async () => {
      daoAddress = accounts[9];
      govAddress = accounts[8];
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
  });

  describe("Setting platform fees", async () => {
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

    it("Set Variable Resource fees.", async () => {
      // 1%
      await stackEscrow.setVariableFees("100", "100");

      await stackEscrow.daoFee.call().then(function (c) {
        var daoFee = c.toString();
        assert.equal(daoFee == "100", true);
      });
      await stackEscrow.govFee.call().then(function (c) {
        var govFee = c.toString();
        assert.equal(govFee == "100", true);
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
    clusterProviderWallet = accounts[1];
    it("addDnsToClusterEntry()", async () => {
      await dnsCluster.addDnsToClusterEntry(
        clusterDns,
        clusterProviderWallet,
        "120.231.231.21",
        "120.231.231.21"
      );
      await dnsCluster.dnsToClusterMetadata(clusterDns).then(function (c) {
        var clusterOwner = c["clusterOwner"];
        assert.equal(clusterOwner == clusterProviderWallet, true);
      });
    });

    // $
    // 80.00
    // /mo
    // $0.11905/hour 0.00198416666/ second
    // 16 GB / 8 CPUs
    // 320 GB SSD Disk
    // 6 TB transfer

    it("addResource()", async () => {
      await resourceFeed.addResource(
        clusterDns,
        "cpu",
        // pricePerUnit
        "8333333000000000",
        // dripRatePerUnit
        "1984",
        { from: clusterProviderWallet }
      );
      await resourceFeed.resources(clusterDns, "cpu").then(function (c) {
        var resourceName = c["name"];
        var pricePerUnit = c["pricePerUnit"];
        var dripRatePerUnit = c["dripRatePerUnit"];
        var votingWeightPerUnit = c["votingWeightPerUnit"];

        assert.equal(resourceName == "cpu", true);
        assert.equal(pricePerUnit == "8333333000000000", true);
        assert.equal(dripRatePerUnit == "1984", true);
        assert.equal(votingWeightPerUnit == "0", true);
      });
    });
  });

  describe("Getting information on rates.", async () => {
    it("Get Drip Rate in USD.", async () => {
      await stackEscrow
        .getResourcesDripRateInUSDT(clusterDns, 1, 1, 1, 1)
        .then((c) => console.log(c.toString()));
    });
  });

  describe("2. Developer buys STACK Tokens from Uni", async () => {
    developerWallet = accounts[4];
    it("Buy Stack Tokens from Uniswap", async () => {
      const uniswapV2Router = await UniswapV2Router.at(UniswapV2RouterAddress);
      var amountOutMin = 0;
      var path = [WETH, StackTokenMainNet];
      var deadline = Math.floor(Date.now() / 1000) + 1200;
      // 0.5 Eth
      var amount = "100000000000000000";

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
        "615000000000000000000",
        {
          from: developerWallet,
        }
      );
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "615000000000000000000", true);
        });
    });
  });
  describe("Cluster owner settles the account for developer.", async () => {
    it("Taking a Snapshot Before Time Testing.", async () => {
      snapshot = await timeMachine.takeSnapshot();
      snapshotId = snapshot["result"];
    });

    it("Update and roll time.", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 24);
      await oracleFeed.update();
    });

    it("SettleAccounts()", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 48);
      assert.equal(
        (await stackToken.balanceOf(clusterProviderWallet)) == "0",
        true
      );

      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var totalDripRatePerSecond = c["totalDripRatePerSecond"];
        });

      await stackEscrow.settleAccounts(developerWallet, clusterDns);
      // Since the fixed fee is dependant on time elapsed and the maximum elapsed time changes based on rate.
      assert.equal(
        (await stackToken.balanceOf(daoAddress)) > "6150000000000000000",
        true
      );
      assert.equal(
        (await stackToken.balanceOf(govAddress)) > "6150000000000000000",
        true
      );
      assert.equal(
        (await stackToken.balanceOf(clusterProviderWallet)) >
          "602699999999000000000",
        true
      );
    });
  });

  describe("Cluster owner settles the account for developer half time though", async () => {
    it("updateResourcesByStackAmount() - 2", async () => {
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
        "615000000000000000000",
        {
          from: developerWallet,
        }
      );
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "615000000000000000000", true);
        });
    });

    it("Settle Accounts ", async () => {
      await timeMachine.advanceTimeAndBlock(6090);
      await stackEscrow.settleAccounts(developerWallet, clusterDns);
    });

    it("rebateAccount()", async () => {
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          beforeRebateAmount = c["totalDeposit"].toString();
        });

      await stackToken.approve(
        stackEscrow.address,
        "900000000000000000000000000",
        {
          from: clusterProviderWallet,
        }
      );

      await stackEscrow.rebateAccount(
        "15000000000000000000",
        developerWallet,
        clusterDns,
        { from: clusterProviderWallet }
      );

      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          const afterRebateAmount = c["totalDeposit"].toString();
          assert.equal(afterRebateAmount > beforeRebateAmount, true);
        });
    });

    it("Withdraw Funds all", async () => {
      assert.equal(
        (await stackToken.balanceOf(stackEscrow.address)) != 0,
        true
      );
      await stackEscrow.withdrawFunds(clusterDns, { from: developerWallet });
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "0", true);
        });
    });
  });
  describe("Adjust the withdraw token allocation settings,", async () => {
    it("setWithdrawTokenPortion()", async () => {
      await stackEscrow.setWithdrawTokenPortion(USDT, 5000, {
        from: clusterProviderWallet,
      });
      await stackEscrow.withdrawSettings(accounts[1]).then(function (c) {
        var address = c["token"].toString();
        var percent = c["percent"].toString();

        assert.equal(address == USDT, true);
        assert.equal(percent == "5000", true);
      });
    });
  });
  describe("Cluster owner settles the account according to the new withdraw settings.", async () => {
    it("updateResourcesByStackAmount() - 3", async () => {
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
        "615000000000000000000",
        {
          from: developerWallet,
        }
      );
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "615000000000000000000", true);
        });
    });

    it("SettleAccounts() - Half in USDT", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 48);
      assert.equal(
        (await stackToken.balanceOf(stackEscrow.address)) ==
          "615000000000000000000",
        true
      );

      await stackEscrow.settleAccounts(developerWallet, clusterDns);
      assert.equal(
        (await usdtToken.balanceOf(clusterProviderWallet)) != 0,
        true
      );

      assert((await stackToken.balanceOf(stackEscrow.address)) == 0, true);
    });
  });
  describe("Partial withdraw and rechargeAccount", async () => {
    it("updateResourcesByStackAmount() - 4", async () => {
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
        "600000000000000000000",
        {
          from: developerWallet,
        }
      );
      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "600000000000000000000", true);
        });
    });

    it("Withdraw Funds partial", async () => {
      assert.equal(
        (await stackToken.balanceOf(stackEscrow.address)) ==
          "600000000000000000000",
        true
      );

      await stackEscrow.withdrawFundsPartial(
        "300000000000000000000",
        clusterDns,
        {
          from: developerWallet,
        }
      );
      assert.equal(
        (await stackToken.balanceOf(stackEscrow.address)) ==
          "300000000000000000000",
        true
      );
    });
    it("rechargeAccount", async () => {
      await stackEscrow.rechargeAccount("300000000000000000000", clusterDns, {
        from: developerWallet,
      });

      await stackEscrow
        .deposits(developerWallet, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          assert.equal(amount == "600000000000000000000", true);
        });
    });
  });

  describe("Deactivate Cluster and try depositing", async () => {
    it("Deactivate Cluster", async () => {
      await dnsCluster.changeClusterStatus(clusterDns, false, {
        from: clusterProviderWallet,
      });
    });
    it("Try updateResourcesByStackAmount", async () => {
      try {
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
          "615000000000000000000",
          {
            from: developerWallet,
          }
        );
        assert.fail("The transaction should have thrown an error");
      } catch (err) {
        assert.include(err.message, "revert", "Deposits are disabled");
      }
    });

    it("Try rechargeAccount", async () => {
      try {
        await stackEscrow.rechargeAccount("300000000000000000000", clusterDns, {
          from: developerWallet,
        });

        assert.fail("The transaction should have thrown an error");
      } catch (err) {
        assert.include(err.message, "revert", "Deposits are disabled");
      }
    });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
