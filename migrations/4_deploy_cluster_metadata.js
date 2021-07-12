const DnsClusterMetadataStore = artifacts.require("DnsClusterMetadataStore");
const ResourceFeed = artifacts.require("ResourceFeed");

module.exports = function (deployer) {
  deployer.then(async () => {
    const resourceFeed = await ResourceFeed.deployed();
    const dnsClusterMetadataStore = await deployer.deploy(
      DnsClusterMetadataStore,
      resourceFeed.address
    );
  });
};
