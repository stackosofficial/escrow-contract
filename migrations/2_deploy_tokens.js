const StackToken = artifacts.require("StackToken");
const token_holder = "0xF0647557Df651ABE5a1BB57E114291F40DB9612f";
module.exports = function (deployer) {
  deployer.then(async () => {
    const stackToken = await deployer.deploy(StackToken,token_holder);
  });
};
