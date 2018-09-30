
const signer = require('../../test/helpers/signer');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

module.exports = function (callback) {
  console.log('====================================');
  console.log('|         CMTA Demo - KYC          |');
  console.log('====================================');
  console.log('\n');

  let validateKYC = async function () {
    console.log('');
    console.log('====================================');
    console.log('Reclaim validation...');
    console.log('');
    
    if (process.argv[5] === 'hash') {
      if (process.argv.length === 8) {
        const boardAddress = process.argv[6];
        const amount = process.argv[7];

        const board = CMTABoardSig.at(boardAddress);
        const distributionAddress = await board.distribution();
        const distribution = CMTAShareDistribution.at(distributionAddress);
       
        console.log('===============================================');
        console.log('Message to sign by board members: ');

        signer.web3 = web3;
        signer.multiSig = board;
        const request = distribution.reclaimShares.request(amount);
        const txHash = await signer.buildHash(
          request.params[0].to, 0, request.params[0].data, 0);

        console.log(txHash);
        console.log('');
        console.log('===============================================');
      } else {
        console.error('Missing arguments:');
        console.error('- board address, amount');
      }
    }

    if (process.argv[5] === 'execute') {
      if (process.argv.length === 10) {
        const boardAddress = process.argv[6];
        const amount = process.argv[7];
        const signedHash1 = process.argv[8];
        const signedHash2 = process.argv[9];
 
        const board = CMTABoardSig.at(boardAddress);
        const distributionAddress = await board.distribution();
        const distribution = CMTAShareDistribution.at(distributionAddress);

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
 
        console.log('Executing...');

        const request = distribution.reclaimShares.request(amount);
        await board.execute(
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ],
          request.params[0].to, 0, request.params[0].data, 0);
        console.log('Reclaim terminated !');
      }
    }
  };

  validateKYC()
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Reclaim terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
