
const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

module.exports = function(callback) {
  console.log('====================================');
  console.log('|     CMTA Demo - Tokenization     |');
  console.log('====================================');
  console.log('\n');

  let accounts;

  let loadConfig = async function () {
    return new Promise((resolve, reject) =>
      web3.eth.getAccounts((err, data) => {
        if(err) {
          reject(err);
        } else {
          accounts = data;
          console.log('Existing accounts: ');
          console.log('(operator) '+accounts[0]);
          console.log('(board1)   '+accounts[1]);
          console.log('(board2)   '+accounts[2]);
          console.log('(board3)   '+accounts[3]);
          resolve(data);
        }
      })
    );
  };

  let tokenizeShares = async function () {
    console.log('');
    console.log('====================================');
    console.log('Tokenizing shares...');
    console.log('');
    
    if(process.argv.length == 9) {
      const boardAddress = process.argv[5];
      const distributionAddress = process.argv[6];
      const signedHash1 = process.argv[7];
      const signedHash2 = process.argv[8];

      const distribution = CMTAShareDistribution.at(distributionAddress);
      const distributionOwner = await distribution.owner();
      if(distributionOwner != boardAddress) {
        return "Wrong Distribution Owner";
      }

      const board = CMTABoardSig.at(boardAddress);
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

      console.log('Board: '+boardAddress);
      console.log('Distribution: '+distributionAddress);
      await board.tokenizeShares(distribution.address,
        [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
      );
      console.log('');
      console.log('Share tokenized !');
    } else {
      console.error('Missing arguments:');
      console.error('- board and distribution address');
      console.error('- 2 signed tokenize share messages');
    }
  }

  loadConfig()
    .then(() => tokenizeShares())
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Signing terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit());
}
