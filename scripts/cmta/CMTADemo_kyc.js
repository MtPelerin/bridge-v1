
const signer = require('../../test/helpers/signer');
const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');

module.exports = function (callback) {
  console.log('====================================');
  console.log('|         CMTA Demo - KYC          |');
  console.log('====================================');
  console.log('\n');

  // Configuration
  // const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;
  const nextYear = 1569329945;

  let validateKYC = async function () {
    console.log('');
    console.log('====================================');
    console.log('KYC validation...');
    console.log('');
    
    if (process.argv[5] === 'hash') {
      if (process.argv.length === 8) {
        const boardAddress = process.argv[6];
        const users = process.argv[7].split(',');

        const board = CMTABoardSig.at(boardAddress);
        const tokenAddress = await board.token();
        const token = CMTAPocToken.at(tokenAddress);

        console.log('===============================================');
        console.log('Message to sign by board members: ');

        signer.web3 = web3;
        signer.multiSig = board;
        const request = token.validateManyKYCUntil.request(users, nextYear);
        console.log(request);
        const txHash = await signer.buildHash(
          request.params[0].to, 0, request.params[0].data, 0);

        console.log(txHash);
        console.log('');
        console.log('===============================================');
      } else {
        console.error('Missing arguments:');
        console.error('- board address, users list');
      }
    }

    if (process.argv[5] === 'execute') {
      if (process.argv.length === 10) {
        const boardAddress = process.argv[6];
        const users = process.argv[7].split(',');
        const signedHash1 = process.argv[8];
        const signedHash2 = process.argv[9];
 
        const board = CMTABoardSig.at(boardAddress);
        const tokenAddress = await board.token();
        const token = CMTAPocToken.at(tokenAddress);

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

        const request = token.validateManyKYCUntil.request(users, nextYear);
        console.log(request);
        await board.execute(
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ],
          request.params[0].to, 0, request.params[0].data, 0);
        console.log('KYC terminated !');
      }
    }
  };

  validateKYC()
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA KYC terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
