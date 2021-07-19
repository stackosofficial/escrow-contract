const DelegatedDepositEscrow = artifacts.require("DelegatedDepositEscrow");
const StackToken = artifacts.require("StackToken");
const ResourceFeed = artifacts.require("ResourceFeed");
const Staking = artifacts.require("Staking");
const DnsClusterMetadataStore = artifacts.require("DnsClusterMetadataStore");
const OracleFeed = artifacts.require("StackOracle");
const _stackosControllerAdress = "0x32e7c0c779325349c5470193f6948d7f25973e38";
const UniswapV2FactoryAddress = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const UniswapV2RouterAddress = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D";
const WETH = "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f";
const USDT = "0xdAC17F958D2ee523a2206206994597C13D831ec7";
const lpstack = "0x635b58600509acFe70e0BD4c4935c08182774e58";
const lpusdt = "0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852";

module.exports = function (deployer) {
  deployer.then(async () => {
    const stackToken = await StackToken.deployed();
    const resourceFeed = await ResourceFeed.deployed();
    const staking = await Staking.deployed();
    const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();
    const oracle = await deployer.deploy(OracleFeed, lpstack, lpusdt);

    const delegatedDepositEscrow = await deployer.deploy(
      DelegatedDepositEscrow,
      stackToken.address,
      resourceFeed.address,
      staking.address,
      dnsClusterMetadataStore.address,
      UniswapV2FactoryAddress,
      UniswapV2RouterAddress,
      _stackosControllerAdress,
      _stackosControllerAdress,
      WETH,
      USDT,
      oracle.address
    );
  });
};
