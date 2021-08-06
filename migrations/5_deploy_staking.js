const Staking = artifacts.require('Staking');
const DnsClusterMetadataStore = artifacts.require('DnsClusterMetadataStore');
const StackToken = artifacts.require('StackToken');
const _stakingAmount = '100000000000000000000';
const _slashFactor = '500000000000000000';
const _rewardsPerUpvote = '100000000000000000';
const _rewardsPerShare = '100000000000000000';
const _daoAddress = '0x7d2f88933e52C352549c748BB572F3c383528fF2';
const _stackTokenAddress = '0x6855f7bb6287F94ddcC8915E37e73a3c9fEe5CF3';

module.exports = function (deployer) {
  deployer.then(async () => {
    const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();
    // const stackToken = await StackToken.deployed();
    const staking = await deployer.deploy(
      Staking,
      dnsClusterMetadataStore.address,
      _stackTokenAddress, //stackToken.address,
      _stakingAmount,
      _slashFactor,
      _rewardsPerUpvote,
      _rewardsPerShare,
      _daoAddress
    );
  });
};
