require('dotenv').config();
require('babel-register');
require('babel-polyfill');

let networks = {};
if (process.env.SOLIDITY_COVERAGE) {
  networks = {
    coverage: {
      host: 'localhost',
      network_id: '*', // eslint-disable-line camelcase
      port: 8555,
      gas: 0xfffffffffff,
      gasPrice: 0x01,
    },
  };
} else {
  const HDWalletProvider = require('truffle-hdwallet-provider');
  const conf = process.env;
  const providerWithMnemonic = (mnemonic, rpcEndpoint) => {
    if(mnemonic && rpcEndpoint) {
      return new HDWalletProvider(mnemonic, rpcEndpoint, 0, 10);
    }
    return undefined;
  }

  let loadNetworks = false;
  for(let i=3; i < process.argv.length && !loadNetworks; i++) {
    loadNetworks = process.argv[i].startsWith('--network');
  }

  if (loadNetworks) {
    networks = {
      'mtpelerin-eth-testnet': {
        provider: providerWithMnemonic(
          conf.TEST_MNEMONIC, conf.TEST_RPC_ENDPOINT),
        network_id: 3,
        gas: 5087795,
        gasPrice: 20000000000,
        host: 'testnet-eth.mtpelerin.com',
      },
       'mtpelerin-eth-testnet-02': {
        provider: providerWithMnemonic(
          conf.TEST_MNEMONIC, conf.TEST_RPC_ENDPOINT),
        network_id: 3,
        gas: 4587795,
        gasPrice: 75000000000,
        host: '163.172.104.223',
      },
      'mtpelerin-eth-mainnet': {
        provider: providerWithMnemonic(
          conf.PROD_MNEMONIC, conf.PROD_RPC_ENDPOINT),
        network_id: 1,
        gas: 4587795,
        gasPrice: 100000000,
        port: 8545,
        host: 'mainnet-eth.mtpelerin.com',
      },
      'mtpelerin-rsk-testnet': {
        network_id: 779,
        gas: 4587795,
        port: 4443,
        host: 'testnet-rsk.mtpelerin.com:4443',
      },
      'mtpelerin-rsk-mainnet': {
        network_id: 775,
        gas: 4587795,
        port: 4443,
        host: 'mainnet-rsk.mtpelerin.com:4444',
      },
      'infura-testnet': {
        provider: providerWithMnemonic(
          conf.TEST_MNEMONIC, conf.TEST_INFURA_RPC_ENDPOINT),
        network_id: 3,
        gas: 4587795,
        gasPrice: 75000000000,
      },
      'infura-kovan': {
        provider: providerWithMnemonic(
          conf.TEST_MNEMONIC, conf.KOVAN_INFURA_RPC_ENDPOINT),
        network_id: 42,
        gas: 4807795,
        gasPrice: 75000000000,
      },
      'infura-mainnet': {
        provider: providerWithMnemonic(
          conf.PROD_MNEMONIC, conf.PROD_INFURA_RPC_ENDPOINT),
        network_id: 1,
        gas: 4807795,
        gasPrice: 5000000000,
      },
      'development': {
        host: "127.0.0.1",
        port: 8545,
        network_id: "*" // Match any network id
      }
    };
  }
}
module.exports = {
  networks: networks,
};
