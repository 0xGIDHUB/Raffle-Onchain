# Raffle OnChain

An Onchain Enabled Lottery

## Description

This is a decentralized raffle apllication built on solidity and foundry. It enables a user to open a raffle which players can participate in and win the grand price after the raffle is closed.

## Getting Started

### Requirements

* [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  * You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
* [foundry](https://getfoundry.sh/)
  * You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

### Installation

All commands are expected to be run on a WSL shell for windows users

#### Clone the repo
Run the following commands
```
git clone https://github.com/0xGIDHUB/foundry-smart-contract-lottery-f25
cd foundry-smart-contract-lottery-f25
```
#### Install make
Run the command
```
sudo apt install make
```

#### Install dependencies
Run the command
```
make install
```

## Usage

### Setup

Setup your environment variables as such:
```
ANVIL_RPC_URL=http://127.0.0.1:8545
ANVIL_PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
SEPOLIA_RPC_URL=pasteyoursepoliarpcurlhere
ETHERSCAN_API_KEY=pasteyouretherscanapikeyhere
```
Run the command:
```
source .env
```

### Testing On Anvil
Run the command:
```
make test-anvil
```

### Testing On Sepolia
Run the command:
```
make test-sepolia
```

### Deploying On Anvil
Setup an anvil node on your terminal, run:
```
make anvil
```
You should get an output like this:
```
                             _   _
                            (_) | |
      __ _   _ __   __   __  _  | |
     / _` | | '_ \  \ \ / / | | | |
    | (_| | | | | |  \ V /  | | | |
     \__,_| |_| |_|   \_/   |_| |_|

    1.0.0-stable (e144b82070 2025-02-13T20:03:31.026474817Z)
    https://github.com/foundry-rs/foundry

Available Accounts
==================

(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000.000000000000000000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000.000000000000000000 ETH)
(2) 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC (10000.000000000000000000 ETH)
(3) 0x90F79bf6EB2c4f870365E785982E1f101E93b906 (10000.000000000000000000 ETH)
(4) 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65 (10000.000000000000000000 ETH)
(5) 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc (10000.000000000000000000 ETH)
(6) 0x976EA74026E726554dB657fA54763abd0C3a0aa9 (10000.000000000000000000 ETH)
(7) 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955 (10000.000000000000000000 ETH)
(8) 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f (10000.000000000000000000 ETH)
(9) 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720 (10000.000000000000000000 ETH)

Private Keys
==================

(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
(1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
(2) 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a
(3) 0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6
(4) 0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a
(5) 0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba
(6) 0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e
(7) 0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356
(8) 0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97
(9) 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

Wallet
==================
Mnemonic:          test test test test test test test test test test test junk
Derivation path:   m/44'/60'/0'/0/


Chain ID
==================

31337

Base Fee
==================

1000000000

Gas Limit
==================

30000000

Genesis Timestamp
==================

1748638531

Listening on 127.0.0.1:8545
```

To deploy the raffle smart contract to local Anvil blockchain run:
```
make deploy-anvil
```
- You should get a similar output to this:
```
[⠰] Compiling...
No files changed, compilation skipped
Script ran successfully.

== Logs ==
  Creating subscription on chain Id:  31337
  Your subscription Id is:  25448741962226539893443353960832642176869692365643085071536008624333042404249
  Please update the subscription Id in your HelperConfig.s.sol
  Funding subscription: 25448741962226539893443353960832642176869692365643085071536008624333042404249
  Using VRF Coordinator: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  On chain Id: 31337
  Adding consumer contract:  0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
  To VRF Coordinator:  0x5FbDB2315678afecb367f032d93F642f64180aa3
  On ChainId:  31337

## Setting up 1 EVM.

==========================

Chain 31337

Estimated gas price: 2.000000001 gwei

Estimated total gas used for script: 6995965

Estimated amount required: 0.013991930006995965 ETH

==========================

##### anvil-hardhat
✅  [Success] Hash: 0x0e192475ae533820bb5df8a52c461de2f4205e99643c3e2ccbec55c911ded035
Contract Address: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Block: 1
Paid: 0.003144815003144815 ETH (3144815 gas * 1.000000001 gwei)



✅ Sequence #1 on anvil-hardhat | Total Paid: 0.005025681990667984 ETH (5356175 gas * avg 0.882964518 gwei)
                                                                                                                                            
==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
```

> **Note**  
> I had to resolve an arithmetic overflow/underflow error when deploying to anvil so if you get a similar error, locate the createSubscription function in the SubscriptionAPI.sol contract inherited by the VRFCoordinatorV2_5.Mock.sol and change the following code block..:
>
> ```subId = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number-1), address(this), currentSubNonce)));```
>
>..to this:
>
> ```subId = uint256(keccak256(abi.encodePacked(msg.sender, blockhash(block.number), address(this), currentSubNonce)));```


### Deploying On Sepolia
Setup your cast wallet by running the command:
```
cast wallet import -i
```
(You will be prompted to input your private key from your web3 wallet e.g metamask)
To deploy the raffle smart contract to sepolia testnet run:
```
make deploy-sepolia
```

You should get a similar output to this:
```
==========================

ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
##
Start verification for (1) contracts
Start verifying contract `0x79C7f54e21a3968D2F0e7582623ab02007A99A9d` deployed on sepolia
Compiler version: 0.8.19
Optimizations:    200
Constructor args: 0000000000000000000000009ddfaca8183c41ad55329bdeed9f6a8d53168b1b787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae9c5e1e895d736c5d5c89fceb39b28c32e1bd0c1d36a7b0186cfd40153097042d000000000000000000000000000000000000000000000000000000000007a120

Submitting verification for [src/Raffle.sol:Raffle] 0x79C7f54e21a3968D2F0e7582623ab02007A99A9d.
Submitted contract for verification:
        Response: `OK`
        GUID: `skfgbkfzlakiipsuvpkfb4vktmyyvk6r2cgenxuxtwhzhiji8t`
        URL: https://sepolia.etherscan.io/address/0x79c7f54e21a3968d2f0e7582623ab02007a99a9d
Contract verification status:
Response: `OK`
Details: `Pass - Verified`
Contract successfully verified
All (1) contracts were verified!
```

You can checkout an already deployed raffle smart contract on [etherscan](https://sepolia.etherscan.io/address/0x79C7f54e21a3968D2F0e7582623ab02007A99A9d#code)


## Author

Gideon Ov  
Twitter: [@0xGIDHUB](https://x.com/0xGIDHUB)


## License

This project is licensed under the MIT License

## Acknowledgments
Much thanks to [Patrick Collins](https://x.com/PatrickAlphaC) and [Cyfrin Updraft](https://www.cyfrin.io/updraft) for providing the learning resources for this project.
