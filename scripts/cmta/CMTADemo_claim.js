
const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

module.exports = function (callback) {
  console.log('====================================');
  console.log('|        CMTA Demo - claim         |');
  console.log('====================================');
  console.log('\n');

  let agreeAndClaims = async function () {
    if (process.argv.length === 6) {
      const boardAddress = process.argv[5];

      const board = CMTABoardSig.at(boardAddress);
      const tokenAddress = await board.token();
      const distributionAddress = await board.distribution();
      const token = CMTAPocToken.at(tokenAddress);
      const distribution = CMTAShareDistribution.at(distributionAddress);

      console.log('loading agreement hashes...');
      const tokenAgreementHash = await token.agreementHash();
      const distributionAgreementHash = await distribution.agreementHash();

      const request1 = token.acceptAgreement.request(tokenAgreementHash);
      console.log('======================================');
      console.log(' TOKEN Agreement hash: ' + tokenAgreementHash);
      console.log('Parameters for accepting the token T&C:');
      console.log(request1);

      console.log('');
      const request2 = distribution.claimShares.request(distributionAgreementHash);
      console.log('Parameters for claiming tokens:');
      console.log(' DISTRIBUTION Agreement hash: ' + distributionAgreementHash);
      console.log(request2);
    } else {
      console.error('Missing arguments:');
      console.error('board address');
    }
  };

  agreeAndClaims()
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Claimm terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
