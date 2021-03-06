const StackEscrow = artifacts.require("StackEscrow");
const StackToken = artifacts.require("StackToken");
const ResourceFeed = artifacts.require("ResourceFeed");
const Staking = artifacts.require("Staking");
const DnsClusterMetadataStore = artifacts.require("DnsClusterMetadataStore");
const OracleFeed = artifacts.require("StackOracle");
const EscrowLib = artifacts.require("EscrowLib");

const dao = "0xE22195fCf831427912bB6681dBbD5B050814e154";
const gov = "0xE22195fCf831427912bB6681dBbD5B050814e154";

// ETHEREUM MAINNET - When running test, uncomment.
// ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
// const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
// const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
// const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
// const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";
// const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
// const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
// ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// BSC
const WETH = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
const USDT = "0x55d398326f99059fF775485246999027B3197955";
const lpstack = "0x17e9216402138B15B30bd341c0377054e42aEbf8";
const lpusdt = "0x16b9a82891338f9bA80E2D6970FddA79D1eb0daE";
const UniswapV2FactoryAddress = "0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73";
const UniswapV2RouterAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";

// BSC Addresses
const _stackTokenAddress = "0x6855f7bb6287F94ddcC8915E37e73a3c9fEe5CF3";
const _resourceFeedAddress = "0x4f355262C63f6E222754D32f20F90913EB2Ba646";
const _dnsClusterMetadataStoreAddress =
  "0x1385B44838EC73b8934e815225bD65b789D3c1D2";
const _stakingAddress = "0xbfb53d536f4B2B767a76C9E3cb9027aB4E1eCb15";

module.exports = function (deployer) {
  deployer.then(async () => {
    // UNCOMMENT WHEN RUNNING FULL TESTS OR DOING FULL DEPLOYMENT
    // ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // const stackToken = await StackToken.deployed();
    // const resourceFeed = await ResourceFeed.deployed();
    // const staking = await Staking.deployed();
    // const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    const oracle = await deployer.deploy(OracleFeed, lpstack, lpusdt, WETH);

    // await deployer.deploy(EscrowLib);
    // await deployer.link(EscrowLib, StackEscrow);

    // const stackEscrow = await deployer.deploy(
    //   StackEscrow,
    //   _stackTokenAddress, //stackToken.address,
    //   _resourceFeedAddress, //resourceFeed.address,
    //   _stakingAddress, //staking.address,
    //   _dnsClusterMetadataStoreAddress, //dnsClusterMetadataStore.address,
    //   UniswapV2FactoryAddress,
    //   UniswapV2RouterAddress,
    //   dao,
    //   gov,
    //   WETH,
    //   USDT,
    //   oracle.address
    // );

    // USE FOR TESTING ON MAINNET
    // const stackEscrow = await deployer.deploy(
    //   StackEscrow,
    //   stackToken.address,
    //   resourceFeed.address,
    //   staking.address,
    //   dnsClusterMetadataStore.address,
    //   UniswapV2FactoryAddress,
    //   UniswapV2RouterAddress,
    //   dao,
    //   gov,
    //   WETH,
    //   USDT,
    //   oracle.address
    // );

    // Setting up the contract below.

    // await stackEscrow.defineResourceVar(1, "cpu");
    // await stackEscrow.defineResourceVar(2, "memory");
    // await stackEscrow.defineResourceVar(3, "disk");
    // await stackEscrow.defineResourceVar(4, "bandwidth");
    // await stackEscrow.defineResourceVar(5, "undefined");
    // await stackEscrow.defineResourceVar(6, "undefined");
    // await stackEscrow.defineResourceVar(7, "undefined");
    // await stackEscrow.defineResourceVar(8, "undefined");

    // await stackEscrow.setFixedFees("dao", [0, 0, 0, 0, 0, 0, 0, 0]);
    // await stackEscrow.setFixedFees("gov", [0, 0, 0, 0, 0, 0, 0, 0]);

    // await stackEscrow.setVariableFees("250", "250");
  });
};
