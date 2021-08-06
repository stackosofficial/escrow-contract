const DnsClusterMetadataStore = artifacts.require('DnsClusterMetadataStore');
const ResourceFeed = artifacts.require('ResourceFeed');
const _resourceFeedAddress = '0x91EA7827647475D0228957d396c5795023d6d4CA';

module.exports = function (deployer) {
  deployer.then(async () => {
    const resourceFeed = await ResourceFeed.deployed();
    const dnsClusterMetadataStore = await deployer.deploy(
      DnsClusterMetadataStore,
      _resourceFeedAddress //resourceFeed.address
    );
  });
};
