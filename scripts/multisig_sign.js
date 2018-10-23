const signer = require('../test/helpers/signer');

module.exports = function (callback) {
  console.log('=====================================');
  console.log('|  Bridge Protocol - signing hash   |');
  console.log('=====================================');
  console.log('\n');

  let signingBoard = async function () {
    console.log('');
    console.log('====================================');
    console.log('Signing message...');
    console.log('');
   
    if (process.argv[6]) {
      const address = process.argv[5];
      const hash = process.argv[6];

      console.log('address=\'' + address + '\'');
      console.log('hash=\'' + hash + '\'');
      signer.web3 = web3;
      const signedHash = this.web3.eth.sign(address, hash);

      const rsv = {
        r: '0x' + signedHash.slice(2).slice(0, 64),
        s: '0x' + signedHash.slice(2).slice(64, 128),
        v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
      };

      console.log('SIGNED MESSAGE   ' + JSON.stringify(rsv));
      console.log('====================================');
    } else {
      console.error('Invalid parameters');
      console.error('Expecting: multisig_sign.js <address> <hash>');
    }
  };

  signingBoard()
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('Bridge Protocol Signing terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
