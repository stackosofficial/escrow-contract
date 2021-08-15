const Staking = artifacts.require('Staking');
const DnsClusterMetadataStore = artifacts.require('DnsClusterMetadataStore');
const StackToken = artifacts.require('StackToken');
const _stakingAmount = '100000000000000000000';
const _slashFactor = '500000000000000000';
const _rewardsPerUpvote = '100000000000000000';
const _rewardsPerShare = '100000000000000000';
const _daoAddress = '0xE22195fCf831427912bB6681dBbD5B050814e154';
const _stackTokenAddress = '0x6855f7bb6287f94ddcc8915e37e73a3c9fee5cf3';
const _dnsclustermetadatastoreAddress = '0x1385B44838EC73b8934e815225bD65b789D3c1D2';

module.exports = function (deployer) {
  deployer.then(async () => {
//    const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();
    // const stackToken = await StackToken.deployed();
    const staking = await deployer.deploy(
      Staking,
      _dnsclustermetadatastoreAddress,
      _stackTokenAddress, //stackToken.address,
      _stakingAmount,
      _slashFactor,
      _rewardsPerUpvote,
      _rewardsPerShare,
      _daoAddress
    );
  });
};
