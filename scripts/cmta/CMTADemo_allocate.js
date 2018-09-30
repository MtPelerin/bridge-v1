
const signer = require('../../test/helpers/signer');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');

module.exports = function (callback) {
  console.log('====================================');
  console.log('|     CMTA Demo - allocation       |');
  console.log('====================================');
  console.log('\n');

  // Configuration
  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let accounts;

  let loadConfig = async function () {
    return new Promise((resolve, reject) =>
      web3.eth.getAccounts((err, data) => {
        if (err) {
          reject(err);
        } else {
          accounts = data;
          console.log('Existing accounts: ');
          console.log('(operator) ' + accounts[0]);
          console.log('(board1)   ' + accounts[1]);
          console.log('(board2)   ' + accounts[2]);
          console.log('(board3)   ' + accounts[3]);
          resolve(data);
        }
      })
    );
  };

  let allocations = async function () {
    console.log('');
    console.log('====================================');
    console.log('Allocating...');
    console.log('');
    
    if (process.argv[5] === 'hash') {
      if (process.argv.length === 7) {
        const boardAddress = process.argv[6];
        const board = CMTABoardSig.at(boardAddress);
        console.log('===============================================');
        console.log('Message to sign by board members: ');

        signer.web3 = web3;
        signer.multiSig = board;
        const txHash = await signer.buildHash(board.address, 0, web3.sha3('ALLOCATE'), 0);

        console.log(txHash);
        console.log('');
        console.log('===============================================');
      } else {
        console.error('Missing arguments:');
        console.error('- board address');
      }
    }

    if (process.argv[5] === 'execute') {
      if (process.argv.length === 11) {
        const boardAddress = process.argv[6];
        const board = CMTABoardSig.at(boardAddress);
        const holders = process.argv[7].split(',');
        const amounts = process.argv[8].split(',').map(x => parseInt(x));
        const signedHash1 = process.argv[9];
        const signedHash2 = process.argv[10];
        
        const rsv1 = {
          r: '0x' + signedHash1.slice(2).slice(0, 64),
          s: '0x' + signedHash1.slice(2).slice(64, 128),
          v: web3.toDecimal(signedHash1.slice(2).slice(128, 130)),
        };
        const rsv2 = {
          r: '0x' + signedHash2.slice(2).slice(0, 64),
          s: '0x' + signedHash2.slice(2).slice(64, 128),
          v: web3.toDecimal(signedHash2.slice(2).slice(128, 130)),
        };
 
        console.log('===============================================');
        console.log('KYC and Allocating holders...');

        await board.validateKYCAndAllocate(
          holders, amounts, nextYear,
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]);
        console.log('Allocation terminated !');
      }
    }
  };

  loadConfig()
    .then(() => allocations())
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Allocation terminated');
    })
    .catch((error) => console.error(error))
    .then(() => process.exit())
    .catch((error) => console.error(error));
};
