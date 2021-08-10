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

  // In the future you need to connect it to the staking contract.

  describe("Set staking Contract. (Temp for testing.)", async () => {
    it("setAddressSetting()", async () => {
      await dnsCluster.setAddressSetting(accounts[0], stackEscrow.address);
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
        1, // cpuMillicore
        // dripRatePerUnit
        "772090000000000",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        2, // diskSpaceGB
        // dripRatePerUnit
        "1",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        3, // requestPerSecond
        // dripRatePerUnit
        "1",
        { from: clusterProviderWallet }
      );

      await resourceFeed.addResource(
        clusterDns,
        4, // memoryMB
        // dripRatePerUnit
        "1",
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

  describe("Getting information on rates.", async () => {
    it("Get Drip Rate in USD.", async () => {
      await stackEscrow
        .getResourcesDripRateInUSDT(clusterDns, [1, 1, 1, 1, 0, 0, 0, 0])
        .then((c) => console.log(c.toString()));
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

    it("updateResourcesByStackAmount()", async () => {
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
  describe("Cluster owner settles the account for developer.", async () => {
    it("SettleAccounts()", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 24);
      // assert.equal(
      //   (await stackToken.balanceOf(clusterProviderWallet)) == "0",
      //   true
      // );
      await stackToken
        .balanceOf(developerWallet)
        .then((c) => console.log("Balance of STACK TOKENS: " + c.toString()));

      await stackEscrow
        .getDeposits(developerWallet, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var totalDripRatePerSecond = c["totalDripRatePerSecond"];
          console.log(totalDeposit);
          console.log(totalDripRatePerSecond);
          //   assert.equal(totalDeposit == "15000000000000000000", true);
          //   assert.equal(totalDripRatePerSecond == "1", true);
        });

      await stackEscrow.settleAccounts(developerWallet, clusterDns);

      await stackEscrow
        .getDeposits(developerWallet, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var totalDripRatePerSecond = c["totalDripRatePerSecond"];
          console.log(totalDeposit);
          console.log(totalDripRatePerSecond);
          //   assert.equal(totalDeposit == "15000000000000000000", true);
          //   assert.equal(totalDripRatePerSecond == "1", true);
        });

      await stackToken
        .balanceOf(clusterProviderWallet)
        .then((c) => console.log(c.toString()));

      //   // Since the fixed fee is dependant on time elapsed and the maximum elapsed time changes based on rate.
      //   assert.equal(
      //     (await stackToken.balanceOf(daoAddress)) > "6150000000000000000",
      //     true
      //   );
      //   assert.equal(
      //     (await stackToken.balanceOf(govAddress)) > "6150000000000000000",
      //     true
      //   );
      //   assert.equal(
      //     (await stackToken.balanceOf(clusterProviderWallet)) >
      //       "602699999999000000000",
      //     true
      //   );
    });
    //   });

    //   describe("Cluster owner settles the account for developer half time though", async () => {
    //     it("updateResourcesByStackAmount() - 2", async () => {
    //       await stackToken
    //         .balanceOf(developerWallet)
    //         .then((c) => console.log(c.toString()));

    //       await stackEscrow.updateResourcesFromStack(
    //         clusterDns,
    //         [1, 1, 1, 1, 1, 1, 0, 0],
    //         "615000000000000000000",
    //         {
    //           from: developerWallet,
    //         }
    //       );
    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           assert.equal(amount == "615000000000000000000", true);
    //         });
    //     });

    //     it("Settle Accounts ", async () => {
    //       await timeMachine.advanceTimeAndBlock(6090);
    //       await stackEscrow.settleAccounts(developerWallet, clusterDns);
    //     });

    //     it("rebateAccount()", async () => {
    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           beforeRebateAmount = c["totalDeposit"].toString();
    //         });

    //       await stackToken.approve(
    //         stackEscrow.address,
    //         "900000000000000000000000000",
    //         {
    //           from: clusterProviderWallet,
    //         }
    //       );

    //       await stackEscrow.rebateAccount(
    //         "15000000000000000000",
    //         developerWallet,
    //         clusterDns,
    //         false,
    //         { from: clusterProviderWallet }
    //       );

    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           const afterRebateAmount = c["totalDeposit"].toString();
    //           assert.equal(afterRebateAmount > beforeRebateAmount, true);
    //         });
    //     });

    //     it("Withdraw Funds all", async () => {
    //       assert.equal(
    //         (await stackToken.balanceOf(stackEscrow.address)) != 0,
    //         true
    //       );
    //       await stackEscrow.withdrawFunds(clusterDns, { from: developerWallet });
    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           var notWithdrawable = c["notWithdrawable"].toString();
    //           assert.equal(amount > "14900000000000000000", true);
    //           assert.equal(notWithdrawable > "14900000000000000000", true);
    //         });
    //     });
    //   });
    //   describe("Adjust the withdraw token allocation settings,", async () => {
    //     it("setWithdrawTokenPortion()", async () => {
    //       await stackEscrow.setWithdrawTokenPortion(USDT, 5000, {
    //         from: clusterProviderWallet,
    //       });
    //     });
    //   });
    //   describe("Cluster owner settles the account according to the new withdraw settings.", async () => {
    //     it("updateResourcesByStackAmount() - 3", async () => {
    //       await stackEscrow.updateResourcesFromStack(
    //         clusterDns,
    //         [1, 1, 1, 1, 1, 1, 0, 0],
    //         "615000000000000000000",
    //         {
    //           from: developerWallet2,
    //         }
    //       );
    //       await stackEscrow
    //         .getDeposits(developerWallet2, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           assert.equal(amount == "615000000000000000000", true);
    //         });
    //     });

    //     it("SettleAccounts() - Half in USDT", async () => {
    //       await timeMachine.advanceTimeAndBlock(60 * 60 * 48);
    //       await stackEscrow.settleAccounts(developerWallet2, clusterDns);
    //       assert.equal(
    //         (await usdtToken.balanceOf(clusterProviderWallet)) != 0,
    //         true
    //       );
    //     });
    //   });
    //   describe("Partial withdraw and rechargeAccount", async () => {
    //     it("updateResourcesByStackAmount() - 4", async () => {
    //       await stackEscrow.updateResourcesFromStack(
    //         clusterDns,
    //         [1, 1, 1, 1, 1, 1, 0, 0],
    //         "600000000000000000000",
    //         {
    //           from: developerWallet3,
    //         }
    //       );
    //       await stackEscrow
    //         .getDeposits(developerWallet3, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           assert.equal(amount == "600000000000000000000", true);
    //         });
    //     });

    //     it("Withdraw Funds partial", async () => {
    //       assert.equal(
    //         (await stackToken.balanceOf(stackEscrow.address)) >=
    //           "600000000000000000000",
    //         true
    //       );

    //       await stackEscrow.withdrawFundsPartial(
    //         "300000000000000000000",
    //         clusterDns,
    //         {
    //           from: developerWallet3,
    //         }
    //       );
    //     });
    //     it("rechargeAccount", async () => {
    //       await stackEscrow.rechargeAccount("300000000000000000000", clusterDns, {
    //         from: developerWallet3,
    //       });

    //       await stackEscrow
    //         .getDeposits(developerWallet3, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           assert.equal(amount > "599000000000000000000", true);
    //         });
    //     });
    //   });

    //   describe("Deactivate Cluster and try depositing", async () => {
    //     it("Deactivate Cluster", async () => {
    //       await dnsCluster.changeClusterStatus(clusterDns, false, {
    //         from: clusterProviderWallet,
    //       });
    //     });
    //     it("Try updateResourcesByStackAmount and fail", async () => {
    //       try {
    //         await stackEscrow.updateResourcesFromStack(
    //           clusterDns,
    //           [1, 1, 1, 1, 1, 1, 0, 0],
    //           "615000000000000000000",
    //           {
    //             from: developerWallet,
    //           }
    //         );
    //         assert.fail("The transaction should have thrown an error");
    //       } catch (err) {
    //         assert.include(err.message, "revert", "Deposits are disabled");
    //       }
    //     });

    //     it("rechargeAccount and succeed", async () => {
    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           var totalDeposit = c["totalDeposit"];
    //           console.log(totalDeposit.toString());
    //         });

    //       await stackEscrow.rechargeAccount("300000000000000000000", clusterDns, {
    //         from: developerWallet,
    //       });
    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           var totalDeposit = c["totalDeposit"];
    //           console.log(totalDeposit.toString());
    //         });
    //     });

    //     it("Re-Enable Cluster", async () => {
    //       await dnsCluster.changeClusterStatus(clusterDns, true, {
    //         from: clusterProviderWallet,
    //       });
    //     });
  });

  describe("Community Grant deposit and issue.", async () => {
    it("Community Grant Deposit communityDeposit()", async () => {
      await stackToken
        .balanceOf(developerWallet)
        .then((c) => console.log(c.toString()));
      await stackEscrow.communityDeposit("300000000000000000000", {
        from: developerWallet,
      });
      await stackEscrow.communityDeposits.call().then(function (c) {
        var totalDeposit = c;
        assert.equal(totalDeposit == "300000000000000000000", true);
      });
    });
    it("Community Grant issue to new Account communityDeposit()", async () => {
      await stackEscrow.issueGrantNewAccount(
        developerWallet2,
        "100000000000000000000",
        clusterDns,
        [1, 1, 1, 1, 0, 0, 0, 0]
      );
      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          var notWithdrawable = c["notWithdrawable"].toString();
          assert.equal(amount == "100000000000000000000", true);
          assert.equal(notWithdrawable == "100000000000000000000", true);
        });
    });

    it("issueGrantRechargeAccount()", async () => {
      await stackEscrow.issueGrantRechargeAccount(
        developerWallet2,
        "100000000000000000000",
        clusterDns
      );

      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var amount = c["totalDeposit"].toString();
          var notWithdrawable = c["notWithdrawable"].toString();
          assert.equal(amount == "200000000000000000000", true);
          assert.equal(notWithdrawable == "200000000000000000000", true);
        });
      await stackToken
        .balanceOf(developerWallet2)
        .then((c) => console.log("The Dev2 Balance is: " + c.toString()));
    });
    it("rechargeAccount and and settle after all funds have been used.", async () => {
      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var notWithdrawable = c["notWithdrawable"];
          console.log(totalDeposit.toString());
          console.log(notWithdrawable.toString());
        });

      await stackEscrow.rechargeAccount("300000000000000000000", clusterDns, {
        from: developerWallet2,
      });
      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var notWithdrawable = c["notWithdrawable"];
          console.log(totalDeposit.toString());
          console.log(notWithdrawable.toString());
        });
    });

    it("settleAccounts()", async () => {
      await timeMachine.advanceTimeAndBlock(60 * 60 * 5);

      await stackEscrow.settleAccounts(developerWallet2, clusterDns);
      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var notWithdrawable = c["notWithdrawable"];
          console.log(totalDeposit.toString());
          console.log(notWithdrawable.toString());
        });
    });
  });
  describe("Make an emergency withdrawal", async () => {
    it("EmergencyRefundByClusterOwner()", async () => {
      await stackEscrow.EmergencyRefundByClusterOwner(
        developerWallet2,
        clusterDns,
        {
          from: clusterProviderWallet,
        }
      );
      await stackEscrow
        .getDeposits(developerWallet2, clusterDns)
        .then(function (c) {
          var totalDeposit = c["totalDeposit"];
          var notWithdrawable = c["notWithdrawable"];
          console.log(totalDeposit.toString());
          console.log(notWithdrawable.toString());
        });
    });

    //   });
    //   describe("Settle Multiple accounts in a cluster.", async () => {
    //     it("settleMultipleAccounts()", async () => {
    //       await timeMachine.advanceTimeAndBlock(60 * 60 * 99);
    //       await stackEscrow.settleMultipleAccounts(clusterDns, 3);
    //       await stackEscrow
    //         .getDeposits(developerWallet2, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           var notWithdrawable = c["notWithdrawable"].toString();
    //           assert.equal(amount == "0", true);
    //           assert.equal(notWithdrawable == "0", true);
    //         });

    //       await stackEscrow
    //         .getDeposits(developerWallet, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           var notWithdrawable = c["notWithdrawable"].toString();
    //           assert.equal(amount == "0", true);
    //           assert.equal(notWithdrawable == "0", true);
    //         });
    //       await stackEscrow
    //         .getDeposits(developerWallet3, clusterDns)
    //         .then(function (c) {
    //           var amount = c["totalDeposit"].toString();
    //           var notWithdrawable = c["notWithdrawable"].toString();
    //           var driprate = c["totalDripRatePerSecond"].toString();
    //           assert.equal(driprate == "0", true);
    //           assert.equal(amount == "0", true);
    //           assert.equal(notWithdrawable == "0", true);
    //         });
    //     });
    //   });

    //   describe("Try getting more resource than the cap allows", async () => {
    //     it("Try updateResourcesByStackAmount and fail", async () => {
    //       try {
    //         await stackEscrow.updateResourcesFromStack(
    //           clusterDns,
    //           [11, 11, 11, 11, 0, 0, 0, 0],
    //           "615000000000000000000",
    //           {
    //             from: developerWallet,
    //           }
    //         );
    //         assert.fail("The transaction should have thrown an error");
    //       } catch (err) {
    //         assert.include(err.message, "revert", "");
    //       }
    //     });
    //   });

    //   describe("Buy Max Resource after previous were settled.", async () => {
    //     it("Try updateResourcesByStackAmount and succeed", async () => {
    //       await stackEscrow.resourceCapacityState(clusterDns).then(function (c) {
    //         var resourceOne = c["resourceOne"].toString();
    //         var resourceTwo = c["resourceTwo"].toString();
    //         var resourceThree = c["resourceThree"].toString();
    //         var resourceFour = c["resourceFour"].toString();
    //         var resourceFive = c["resourceFive"].toString();
    //         var resourceSix = c["resourceSix"].toString();
    //         assert.equal(resourceOne == 0, true);
    //         assert.equal(resourceTwo == 0, true);
    //         assert.equal(resourceThree == 0, true);
    //         assert.equal(resourceFour == 0, true);
    //         assert.equal(resourceFive == 0, true);
    //         assert.equal(resourceSix == 0, true);
    //       });

    //       await stackToken
    //         .balanceOf(developerWallet)
    //         .then((c) => console.log(c.toString()));

    //       await stackEscrow.updateResourcesFromStack(
    //         clusterDns,
    //         [10, 10, 10, 10, 0, 0, 0, 0],
    //         "615000000000000000000",
    //         {
    //           from: developerWallet,
    //         }
    //       );
    //     });

    it("Revert to Before Snapshot", async () => {
      await timeMachine.revertToSnapshot(snapshotId);
    });
  });
});
