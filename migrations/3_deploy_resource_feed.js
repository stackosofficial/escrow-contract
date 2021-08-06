const ResourceFeed = artifacts.require("ResourceFeed");
const StackToken = artifacts.require("StackToken");
const usdtAddress = "0xdac17f958d2ee523a2206206994597c13d831ec7";

module.exports = function (deployer) {
  deployer.then(async () => {
    const stackToken = await StackToken.deployed();
    const resourceFeed = await deployer.deploy(
      ResourceFeed,
      stackToken.address
    );
  });
};
