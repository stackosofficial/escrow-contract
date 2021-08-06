const StackEscrow = artifacts.require("StackEscrow");
const StackToken = artifacts.require("StackToken");
const ResourceFeed = artifacts.require("ResourceFeed");
const Staking = artifacts.require("Staking");
const DnsClusterMetadataStore = artifacts.require("DnsClusterMetadataStore");
const OracleFeed = artifacts.require("StackOracle");
const EscrowLib = artifacts.require("EscrowLib");

const dao = "0x77c940F10a7765B49273418aDF5750979718e85f";
const gov = "0x77c940F10a7765B49273418aDF5750979718e85f";
const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

module.exports = function (deployer) {
  deployer.then(async () => {
    const stackToken = await StackToken.deployed();
    const resourceFeed = await ResourceFeed.deployed();
    const staking = await Staking.deployed();
    const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();

    const oracle = await deployer.deploy(OracleFeed, lpstack, lpusdt, WETH);

    await deployer.deploy(EscrowLib);
    await deployer.link(EscrowLib, StackEscrow);

    const stackEscrow = await deployer.deploy(
      StackEscrow,
      stackToken.address,
      resourceFeed.address,
      staking.address,
      dnsClusterMetadataStore.address,
      UniswapV2FactoryAddress,
      UniswapV2RouterAddress,
      dao,
      gov,
      WETH,
      USDT,
      oracle.address
    );

    await stackEscrow.defineResourceVar(1, "cpuMillicore");
    await stackEscrow.defineResourceVar(2, "diskSpaceGB");
    await stackEscrow.defineResourceVar(3, "requestPerSecond");
    await stackEscrow.defineResourceVar(4, "memoryMB");
    await stackEscrow.defineResourceVar(5, "undefined");
    await stackEscrow.defineResourceVar(6, "undefined");
    await stackEscrow.defineResourceVar(7, "undefined");
    await stackEscrow.defineResourceVar(8, "undefined");

    await stackEscrow.setFixedFees("dao", [10, 10, 10, 10, 10, 10, 10, 10]);
    await stackEscrow.setFixedFees("gov", [10, 10, 10, 10, 0, 0, 0, 0]);

    await stackEscrow.setVariableFees("100", "100");
  });
};
