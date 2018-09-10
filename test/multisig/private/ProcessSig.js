'user strict';

/**
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 */

const assertRevert = require('../../helpers/assertRevert');
const ProcessSig = artifacts.require('../contracts/multisig/private/ProcessSig.sol');

contract('ProcessSig', function (accounts) {
  let processSig;

  beforeEach(async function () {
    processSig = await ProcessSig.new([ accounts[1] ], 1);
  });

  it('should not accept any ETH', async function () {
    await assertRevert(
      new Promise((resolve, reject) => web3.eth.sendTransaction({
        from: accounts[0],
        to: processSig.address,
        value: web3.toWei(1, 'milli'),
      }, (err, data) => {
        if (err) {
          reject(err);
        } else {
          resolve();
        }
      }))
    );
  });
});
