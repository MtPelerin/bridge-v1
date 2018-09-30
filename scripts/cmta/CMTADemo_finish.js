
const signer = require('../../test/helpers/signer');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

module.exports = function (callback) {
  console.log('====================================');
  console.log('|  CMTA Demo - Finish allocation   |');
  console.log('====================================');
  console.log('\n');

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
    console.log('Finish allocating...');
    console.log('');
    
    if (process.argv[5] === 'hash') {
      if (process.argv.length === 7) {
        const boardAddress = process.argv[6];
        const board = CMTABoardSig.at(boardAddress);
        console.log('===============================================');
        console.log('Message to sign by board members: ');

        signer.web3 = web3;
        signer.multiSig = board;

        const distributionAddress = await board.distribution();
        const distribution = CMTAShareDistribution.at(distributionAddress);
        const request = await distribution.finishAllocations.request();
        const txHash = await signer.buildHash(
          request.params[0].to, 0, request.params[0].data, 0);

        console.log(txHash);
        console.log('');
        console.log('===============================================');
      } else {
        console.error('Missing arguments:');
        console.error('- board address');
      }
    }

    if (process.argv[5] === 'execute') {
      if (process.argv.length === 9) {
        const boardAddress = process.argv[6];
        const board = CMTABoardSig.at(boardAddress);
        const signedHash1 = process.argv[7];
        const signedHash2 = process.argv[8];

        const distributionAddress = await board.distribution();
        const distribution = CMTAShareDistribution.at(distributionAddress);
        const request = await distribution.finishAllocations.request();
        
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
 
        await board.execute(
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ],
          request.params[0].to, 0, request.params[0].data, 0);
        console.log('executed...');
      } else {
        console.error('Missing arguments:');
        console.error('- board address and 2 signatures');
      }
    }
  };

  loadConfig()
    .then(() => allocations())
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA finish Allocation terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
