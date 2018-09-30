module.exports = function (callback) {
  console.log('Listing balances:');

  let balances = function () {
    return new Promise((resolve, reject) =>
      web3.eth.getAccounts((err, data) => {
        if (err) {
          reject(err);
        } else {
          let promises = [];
          data.forEach(account => {
            let promise = new Promise((resolve, reject) => {
              web3.eth.getBalance(account, (err, data) => {
                if (err) {
                  reject(err);
                } else {
                  console.log(account + ': ' + web3.fromWei(data, 'ether'));
                  resolve();
                }
              });
            });
            promises.push(promise);
          });
          resolve(promises);
        }
      })
    ).then((promises) =>
      Promise.all(promises));
  };

  balances()
    .catch((error) => console.error(error))
    .then(() => process.exit())
    .catch((error) => console.error(error));
};
