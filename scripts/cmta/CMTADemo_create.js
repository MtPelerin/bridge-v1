
const signer = require('../../test/helpers/signer');
const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

module.exports = function(callback) {
  console.log('====================================');
  console.log('|        CMTA Demo - create        |');
  console.log('====================================');
  console.log('\n');

  // Configuration
//  const tokenAgreementHash =        '0xb0e5446a81a3d2d295c67fb7a527539f1311508f9113e77fb2657ab7f85a0ae5';
  const distributionAgreementHash = '0xcbecd9df481048eca42ff17d095d5e987eaa068f056b6d51cab5a9e5c8db651d';
  const tokenAgreementHash   =        '0x0000000000000000000000000000000000000000000000000000000000000000';
//  const distributionAgreementHash   = '0x0000000000000000000000000000000000000000000000000000000000000000';

  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let accounts;
  let token, distribution, board;

  let boardMembers = [];
  let loadConfig = async function () {
    return new Promise((resolve, reject) =>
      web3.eth.getAccounts((err, data) => {
        if(err) {
          reject(err);
        } else {
          accounts = data;
          boardMembers = [
            accounts[1], accounts[2], accounts[3]
          ];

          console.log('Existing accounts: ');
          console.log('(operator) '+accounts[0]); // Moi (Cyril)
          console.log('(board1)   '+boardMembers[0]); // Alphonse
          console.log('(board2)   '+boardMembers[1]); // Ursula
          console.log('(board3)   '+boardMembers[2]); // Robert
          resolve(data);
        }
      })
    );
  };

  // Step 1 Preparing distribution
  let preparingDistribution = async function () {
    console.log('');
    console.log('====================================');
    console.log('1- Preparing distribution contracts...');
    console.log('');

    //    token = await CMTAPocToken.new(
    //       'MyCompany', 'MCY', 100000, 'My Company SA', '0ABCDEFG', 'https://ge.ch/', 100, tokenAgreementHash);
    token = await CMTAPocToken.new(
      'Fedor', // Token name
      'FED', // Token symbol
      100000, // Supply
      'Opus Nigrum SA', // Name of issuer
      'CHE-360.593.404', // Registered number (UID)
      'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-360.593.404&lang=EN', // Url to registry
      100, // value per share in CHF (cents)
      tokenAgreementHash);
    console.log('Token (NEW): '+token.address);

    distribution = await CMTAShareDistribution.new(
      distributionAgreementHash,
      0);
    console.log('Distribution (NEW): '+distribution.address);
    console.log('');

    const distributionToken = await distribution.token();
    if(new Number(distributionToken) == 0) {
      console.log('Setting token to be used in the distribution');
      await distribution.configureToken(token.address, tokenAgreementHash);
    }

    const distributionBalance = await token.balanceOf(distribution.address);
    if(distributionBalance == 0) {
      console.log('Transfer all tokens into distribution contract');
      const supply = await token.totalSupply();
      await token.transfer(distribution.address, supply);
    }

    console.log('Validating the KYC for the distribution contract');
    await token.validateKYCUntil(distribution.address, nextYear);

    console.log('');
    console.log('Token distribution contracts looks good !');
  }

  // Step 2 Meet the board
  let meetTheBoard = async function () {
    console.log('');
    console.log('====================================');
    console.log('2- Meet the board...');
    console.log('');
    board = await CMTABoardSig.new( boardMembers, 2);
    console.log('Board (NEW): '+board.address);
    console.log('');

    const tokenOwner = await token.owner();
    if(tokenOwner != board.address) {
      console.log('Giving token control to the board');
      await token.transferOwnership(board.address);
    }

    const distributionOwner = await distribution.owner();
    if(distributionOwner != board.address) {
      console.log('Giving distribution control to the board');
      await distribution.transferOwnership(board.address);
    }

    const boardToken = await board.token();
    if(boardToken != token.address) {
      console.log('Tokenizing shares as define in the distribution');
      console.log('');
      console.log('===============================================');
      console.log('Message to sign by board members: ');

      signer.web3 = web3;
      signer.multiSig = board;
      const txHash = await signer.buildHash(distribution.address, 0, web3.sha3('TOKENIZE'), 0);

      console.log(txHash);
      console.log('');
      console.log('===============================================');
    }
    console.log('');
    console.log('The board is ready for the distribution !');
  };

  loadConfig()
    .then(() => preparingDistribution())
    .then(() => meetTheBoard())
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Demo end...');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit());
}
