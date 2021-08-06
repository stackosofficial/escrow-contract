const StackEscrow = artifacts.require('StackEscrow');
const StackToken = artifacts.require('StackToken');
const ResourceFeed = artifacts.require('ResourceFeed');
const Staking = artifacts.require('Staking');
const DnsClusterMetadataStore = artifacts.require('DnsClusterMetadataStore');
const OracleFeed = artifacts.require('StackOracle');
const EscrowLib = artifacts.require('EscrowLib');

const dao = '0xC6cDFD798dDa2Cc4Ca2601975366dc1ddF0Bc7E6';
const gov = '0xC6cDFD798dDa2Cc4Ca2601975366dc1ddF0Bc7E6';
const UniswapV2FactoryAddress = '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f';
const UniswapV2RouterAddress = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';
const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const USDT = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const lpstack = '0x17e9216402138B15B30bd341c0377054e42aEbf8';
const lpusdt = '0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852';
const _stackTokenAddress = '0x6855f7bb6287F94ddcC8915E37e73a3c9fEe5CF3';
const _resourceFeedAddress = '0x91EA7827647475D0228957d396c5795023d6d4CA';
const _dnsClusterMetadataStoreAddress =
  '0x2B01ADcA9A6b063f8FE7a4BE044De3553dF0F1EF';
const _stakingAddress = '0x8926e5A2aAC634B394744E77348d5b99b311c49e';

module.exports = function (deployer) {
  deployer.then(async () => {
    // const stackToken = await StackToken.deployed();
    // const resourceFeed = await ResourceFeed.deployed();
    // const staking = await Staking.deployed();
    // const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();

    const oracle = await deployer.deploy(OracleFeed, lpstack, lpusdt, WETH);

    await deployer.deploy(EscrowLib);
    await deployer.link(EscrowLib, StackEscrow);

    const stackEscrow = await deployer.deploy(
      StackEscrow,
      _stackTokenAddress, //stackToken.address,
      _resourceFeedAddress, //resourceFeed.address,
      _stakingAddress, //staking.address,
      _dnsClusterMetadataStoreAddress, //dnsClusterMetadataStore.address,
      UniswapV2FactoryAddress,
      UniswapV2RouterAddress,
      dao,
      gov,
      WETH,
      USDT,
      oracle.address
    );

    await stackEscrow.defineResourceVar(1, 'cpu');
    await stackEscrow.defineResourceVar(2, 'memory');
    await stackEscrow.defineResourceVar(3, 'disk');
    await stackEscrow.defineResourceVar(4, 'bandwidth');
    await stackEscrow.defineResourceVar(5, 'undefined');
    await stackEscrow.defineResourceVar(6, 'undefined');
    await stackEscrow.defineResourceVar(7, 'undefined');
    await stackEscrow.defineResourceVar(8, 'undefined');

    await stackEscrow.setFixedFees('dao', [10, 10, 10, 10, 10, 10, 10, 10]);
    await stackEscrow.setFixedFees('gov', [10, 10, 10, 10, 0, 0, 0, 0]);

    await stackEscrow.setVariableFees('100', '100');
  });
};
