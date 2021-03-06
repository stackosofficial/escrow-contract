/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */
const HDWalletProvider = require("@truffle/hdwallet-provider");
const infuraKey = "2a71d34abc2c4388bf4a83a5b01d8517";
const web3 = require("web3");
const fs = require("fs");
const privateKey = fs.readFileSync(".key").toString().trim();
module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
   api_keys: {
    bscscan: 'IWJ85ZYMYPF4FPWZQFXSG9GQBHQTHSWXGD',
    etherscan: '3QJ6JYQ7QCECPKK2MDZ2W9U3YBKUJ3GF24'
  },
  plugins: ["truffle-contract-size","truffle-plugin-verify"],
  networks: {
    // Useful for testing. The `development` name is special - truffle uses it by default
    // if it's defined here and no other network is specified at the command line.
    // You should run a client (like ganache-cli, geth or parity) in a separate terminal
    // tab if you use this network and you must also set the `host`, `port` and `network_id`
    // options below to some value.
    //
    development: {
      // provider: () =>
      //   new HDWalletProvider([privateKey], `http://127.0.0.1:8545`, 0, 1),
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Any network (default: none)
    },
    // Another network with more advanced options...
    // advanced: {
    // port: 8777,             // Custom port
    // network_id: 1342,       // Custom network
    // gas: 8500000,           // Gas sent with each transaction (default: ~6700000)
    // gasPrice: 20000000000,  // 20 gwei (in wei) (default: 100 gwei)
    // from: <address>,        // Account to send txs from (default: accounts[0])
    // websockets: true        // Enable EventEmitter interface for web3 (default: false)
    // },
    // Useful for deploying to a public network.
    // NB: It's important to wrap the provider as a function.
    zeus: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://eth-privatenet.stackos.io/zeus`,
          0,
          1
        ),
      network_id: "*",
    },
    kovan: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://kovan.infura.io/v3/${infuraKey}`,
          0,
          1
        ),
      network_id: "42",
      production: true,
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000, // # of blocks before a deployment times out  (minimum/default: 50),
      networkCheckTimeout: 200000,
    },
    ropsten: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://ropsten.infura.io/v3/${infuraKey}`,
          0,
          1
        ),
      network_id: "3",
      production: true,
    },
    bscTestnet: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://data-seed-prebsc-1-s1.binance.org:8545/`,
          0,
          1
        ),
      network_id: 97, // Kovan's id
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000, // # of blocks before a deployment times out  (minimum/default: 50),
      networkCheckTimeout: 200000,
    },
    mainnet: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://mainnet.infura.io/v3/${infuraKey}`,
          0,
          1
        ),
      network_id: 1, // mainnet's id
      timeoutBlocks: 2000, // # of blocks before a deployment times out  (minimum/default: 50),
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      gasPrice: web3.utils.toWei("140", "gwei"),
    },
    bscMainnet: {
      provider: () =>
        new HDWalletProvider(
          [privateKey],
          `https://bsc-dataseed.binance.org/`,
          0,
          1
        ),
      network_id: 56, // BSCMainnet's id
      confirmations: 2, // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 2000, // # of blocks before a deployment times out  (minimum/default: 50)
      gasPrice: 6000000000, // 6 gwei
    },
    // Useful for private networks
    // private: {
    // provider: () => new HDWalletProvider(mnemonic, `https://network.io`),
    // network_id: 2111,   // This network is yours, in the cloud.
    // production: true    // Treats this network as if it was a public net. (default: false)
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.6.12", // Fetch exact version from solc-bin (default: truffle's version)
      // docker: true,        // Use "0.5.1" you've installed locally with docker (default: false)
      // settings: {          // See the solidity docs for advice about optimization and evmVersion
      //  optimizer: {
      //    enabled: true,
      //    runs: 20
      //  },
      // evmVersion: "byzantium"
      // }
    },
  },
};
