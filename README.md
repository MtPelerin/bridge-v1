# Mt Pelerin Bridge Protocol
Mt Pelerin smart contracts repository

Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved.  
This content cannot be used, copied or reproduced in part or in whole
without the express and written permission of Mt Pelerin Group SA.  
Written by **Mt Pelerin Group SA**, <info@mtpelerin.com>.  
All matters regarding the intellectual property of this code or software are subjects to Swiss Law without reference to its conflicts of law rules.  

## How it works?

+ [Mt Pelerin's Bridge Token in detail](./Tokens.md)
+ [Token sale](./Tokensale.md)
+ [The Mt Pelerin blockchain bank project](./MtPelerin.md)

## Experiment with it !

#### Setup the truffle environment

1. Install Docker (on Ubuntu)

The documentation is available on the official Docker website
[Install Docker for Ubuntu](https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository)

2. Build the environment

The script **build.sh** will build the docker image *MtPelerin-protocol* locally.
Therefore, the user need to be a sudoer and it will request root privileges to run.

```bash
./build.sh
```

3. Start the environment

The script **start.sh** will run docker with the *MtPelerin-protocol* image.
Therefore, the user need to be a sudoer and it will request root privileges to run.

```bash
./start.sh
```

4. Configure the environment

Copy the *.env.example* into *.env* file and edit the values inside

```bash
cp .env.example .env
```

In particular there is the following environment variables to configure:
- MNEMONIC: seed to use for generating the HDWallet to be used with truffle
- ENDPOINT: the rpc endpoint of the node to be use to connect to the blockchain

5. Install NodeJS dependencies

Execute the following command:
```bash
npm install
```

#### Running the testcase

```bash
truffle test
```

Running the linting
```bash
npm run lint:all
```

With the coverage
```bash
npm run coverage
```

The latest coverage result may be found [here](https://mtpelerin.github.io/MtPelerin-protocol/coverage/)

#### Running the console

```bash
truffle console --network=mtpelerin-eth-testnet
```

#### Contracts Directories
+ **zeppelin**: contains the awesome [open-zeppelin](https://github.com/OpenZeppelin/OpenZeppelin-solidity) dependencies
+ **interface**: contains the interface to be used by DAPP. Interface can also be easily integrated without the need to know the implementations. Due to solidity limitation with 'interface', Abstract 'contracts' are used instead. The resulting ABI is identical.
+ **token**: contains the various token features (which will be used to tokenize Shares, Fiat, Loans, etc.)
+ **tokensale**: tokensale or crowdsale contracts
+ **rule**: contains the rules on transfers which can be applied to other contracts, in particular tokenWithRules
+ **claimable**: contains the claims which can be provided to other contracts, in particular tokenWithClaims
+ **multisig**: Public/Private multisig. Public multisig offer offchain security at the expense of less privacy. Private does not.
+ **cmta**: Standardization of Security Tokens on behalf of the CMTA
+ **mock**: mock are used for the testcases. There are not meant to be used in real situation.
