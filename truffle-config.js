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
      return new HDWalletProvider(mnemonic, rpcEndpoint);
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
        gas: 4587795,
        gasPrice: 2000000000,
        host: 'testnet-eth.mtpelerin.com',
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
    };
  }
}
module.exports = {
  networks: networks,
};
