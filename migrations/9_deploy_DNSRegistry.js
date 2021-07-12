const DNSRegistry = artifacts.require("DNSRegistry");

const expirationPeriod = 5;
const minLengthDomain = 5;

module.exports = function (deployer) {
  deployer.then(async () => {
    await deployer.deploy(DNSRegistry, expirationPeriod, minLengthDomain);
  });
};
