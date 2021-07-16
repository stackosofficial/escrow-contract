```
npm install
```

## Compilation

```
truffle compile --all
```

## Test

Sign up on infura.

Ethereum API | IPFS API & Gateway | ETH Nodes as a Service | Infura

Create Project.

https://infura.io/dashboard/ethereum

Select the project you created

Go under settings

Select the Testnet you want to run it on.

Copy paste the link "https://mainnet.infura.io/v3/...."

Start Ganache-CLI mainet hardfork

```
ganache-cli --fork https://mainnet.infura.io/v3/ -p 7545
```

Run Ganache for testing.

```
truffle test test/EscrowTest.js --network development

```

## StackOS Architecture

![](StackOS_Architecture.png)
