"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
var _exportNames = {
  BASE_TEN: true,
  ADDRESS_ZERO: true,
  encodeParameters: true,
  prepare: true,
  deploy: true,
  createSLP: true,
  getBigNumber: true
};
exports.encodeParameters = encodeParameters;
exports.prepare = prepare;
exports.deploy = deploy;
exports.createSLP = createSLP;
exports.getBigNumber = getBigNumber;
exports.ADDRESS_ZERO = exports.BASE_TEN = void 0;

var _hardhat = require("hardhat");

var _time = require("./time");

Object.keys(_time).forEach(function (key) {
  if (key === "default" || key === "__esModule") return;
  if (Object.prototype.hasOwnProperty.call(_exportNames, key)) return;
  if (key in exports && exports[key] === _time[key]) return;
  Object.defineProperty(exports, key, {
    enumerable: true,
    get: function () {
      return _time[key];
    }
  });
});

// const BigNumber = require("ethers");

const BASE_TEN = 10;
exports.BASE_TEN = BASE_TEN;
const ADDRESS_ZERO = "0x0000000000000000000000000000000000000000";
exports.ADDRESS_ZERO = ADDRESS_ZERO;

function encodeParameters(types, values) {
  const abi = new _hardhat.ethers.utils.AbiCoder();
  return abi.encode(types, values);
}

async function prepare(thisObject, contracts) {
  for (let i in contracts) {
    let contract = contracts[i];
    thisObject[contract] = await _hardhat.ethers.getContractFactory(contract);
  }

  thisObject.signers = await _hardhat.ethers.getSigners();
  thisObject.alice = thisObject.signers[0];
  thisObject.bob = thisObject.signers[1];
  thisObject.carol = thisObject.signers[2];
  thisObject.dev = thisObject.signers[3];
  thisObject.alicePrivateKey = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
  thisObject.bobPrivateKey = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d";
  thisObject.carolPrivateKey = "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a";
}

async function deploy(thisObject, contracts) {
  for (let i in contracts) {
    let contract = contracts[i];
    thisObject[contract[0]] = await contract[1].deploy(...(contract[2] || []));
    await thisObject[contract[0]].deployed();
  }
}

async function createSLP(thisObject, name, tokenA, tokenB, amount) {
  const createPairTx = await thisObject.factory.createPair(tokenA.address, tokenB.address);
  const _pair = (await createPairTx.wait()).events[0].args.pair;
  thisObject[name] = await thisObject.UniswapV2Pair.attach(_pair);
  await tokenA.transfer(thisObject[name].address, amount);
  await tokenB.transfer(thisObject[name].address, amount);
  await thisObject[name].mint(thisObject.alice.address);
} // Defaults to e18 using amount * 10^18


function getBigNumber(amount, decimals = 18) {
  return BigNumber.from(amount).mul(BigNumber.from(BASE_TEN).pow(decimals));
}