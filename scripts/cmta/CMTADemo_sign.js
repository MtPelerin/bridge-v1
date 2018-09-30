
module.exports = function (callback) {
  console.log('====================================');
  console.log('|     CMTA Demo - signing hash     |');
  console.log('====================================');
  console.log('\n');

  // Configuration

  let accounts;
  let boardMembers;

  let loadConfig = async function () {
    return new Promise((resolve, reject) =>
      web3.eth.getAccounts((err, data) => {
        if (err) {
          reject(err);
        } else {
          accounts = data;
          boardMembers = [
            accounts[1], accounts[2], accounts[3],
          ];

          console.log('Existing accounts: ');
          console.log('(operator) ' + accounts[0]);
          console.log('(board1)   ' + boardMembers[0]);
          console.log('(board2)   ' + boardMembers[1]);
          console.log('(board3)   ' + boardMembers[2]);
          resolve(data);
        }
      })
    );
  };

  let signingBoard = async function () {
    console.log('');
    console.log('====================================');
    console.log('Signing message...');
    console.log('');
    
    if (process.argv[5]) {
      const hash = process.argv[5];
      const signedHash1 = this.web3.eth.sign(boardMembers[0], hash);
      const signedHash2 = this.web3.eth.sign(boardMembers[1], hash);
      const signedHash3 = this.web3.eth.sign(boardMembers[2], hash);

      console.log('(board1)   ' + signedHash1);
      console.log('(board2)   ' + signedHash2);
      console.log('(board3)   ' + signedHash3);
      console.log('====================================');
    } else {
      console.error('No message hash to sign');
    }
  };

  loadConfig()
    .then(() => signingBoard())
    .then(() => {
      console.log('');
      console.log('====================================');
      console.log('CMTA Signing terminated');
    })
    .catch((error) => {
      console.error(error);
    }).then(() => process.exit())
    .catch((error) => {
      console.error(error);
    });
};
