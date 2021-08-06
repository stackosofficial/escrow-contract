const ResourceFeed = artifacts.require('ResourceFeed');
const StackToken = artifacts.require('StackToken');
const usdtAddress = '0xdac17f958d2ee523a2206206994597c13d831ec7';
const _stackTokenAddress = '0x6855f7bb6287F94ddcC8915E37e73a3c9fEe5CF3';

module.exports = function (deployer) {
  deployer.then(async () => {
    // const stackToken = await StackToken.deployed();
    const resourceFeed = await deployer.deploy(
      ResourceFeed,
      _stackTokenAddress //stackToken.address
    );
  });
};
