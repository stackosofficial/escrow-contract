const StackFarmer = artifacts.require("StackFarmer");
const StackToken = artifacts.require("StackToken");

// const startBlock = ;
// const stackPerBlock = ;
// const bonusEndBlock = ;
// const devAddress = "";

const startBlock = 24191584;
const stackPerBlock = 100000000000000;
const bonusEndBlock = 24212948;
//const devAddress = "0xC6cDFD798dDa2Cc4Ca2601975366dc1ddF0Bc7E6";

module.exports = function (deployer) {
  deployer.then(async () => {
    const stackToken = await StackToken.deployed();
    await deployer.deploy(
      StackFarmer,
      stackToken.address,
//      devAddress,
      stackPerBlock,
      startBlock,
      bonusEndBlock
    );
  });
};
