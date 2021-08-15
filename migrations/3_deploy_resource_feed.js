const ResourceFeed = artifacts.require('ResourceFeed');
const StackToken = artifacts.require('StackToken');
const usdtAddress = '0x55d398326f99059ff775485246999027b3197955';
const _stackTokenAddress = '0x6855f7bb6287f94ddcc8915e37e73a3c9fee5cf3';

module.exports = function (deployer) {
  deployer.then(async () => {
    // const stackToken = await StackToken.deployed();
    const resourceFeed = await deployer.deploy(
      ResourceFeed,
      _stackTokenAddress //stackToken.address
    );
  });
};
