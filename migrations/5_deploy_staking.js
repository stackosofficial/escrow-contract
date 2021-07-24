const Staking = artifacts.require("Staking");
const DnsClusterMetadataStore = artifacts.require("DnsClusterMetadataStore");
const StackToken = artifacts.require("StackToken");
const _stakingAmount = "100000000000000000000";
const _slashFactor = "500000000000000000";
const _rewardsPerUpvote = "100000000000000000";
const _rewardsPerShare = "100000000000000000";

module.exports = function (deployer) {
  deployer.then(async () => {
    const dnsClusterMetadataStore = await DnsClusterMetadataStore.deployed();
    const stackToken = await StackToken.deployed();
    const staking = await deployer.deploy(
      Staking,
      dnsClusterMetadataStore.address,
      stackToken.address,
      _stakingAmount,
      _slashFactor,
      _rewardsPerUpvote,
      _rewardsPerShare
    );
  });
};
