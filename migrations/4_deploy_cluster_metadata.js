const DnsClusterMetadataStore = artifacts.require('DnsClusterMetadataStore');
const ResourceFeed = artifacts.require('ResourceFeed');
const _resourceFeedAddress = '0x4f355262C63f6E222754D32f20F90913EB2Ba646';

module.exports = function (deployer) {
  deployer.then(async () => {
    const resourceFeed = await ResourceFeed.deployed();
    const dnsClusterMetadataStore = await deployer.deploy(
      DnsClusterMetadataStore,
      _resourceFeedAddress //resourceFeed.address
    );
  });
};
