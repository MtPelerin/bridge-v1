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
const signer = require('../../helpers/signer');
const CancellableSig = artifacts.require('../contracts/multisig/private/CancellableSig.sol');

contract('CancellableSig', function (accounts) {
  let cancellableSig;
  let rsv;

  describe('with one address and threshold of 1', function () {
    beforeEach(async function () {
      cancellableSig = await CancellableSig.new([ accounts[1] ], 1);
      signer.multiSig = cancellableSig;
      
      rsv = await signer.sign(accounts[1], 0, web3.toHex('data'), 0, accounts[1]);
      
      const review = await cancellableSig.reviewSignatures(
        accounts[1], 0, web3.toHex('data'), 0,
        [ rsv.r ], [ rsv.s ], [ rsv.v ]);
      assert.equal(review.toNumber(), 1);
    });

    it('should not cancel when not a signer', async function () {
      await assertRevert(cancellableSig.cancel());
    });

    it('should cancel a transaction when signer', async function () {
      await cancellableSig.cancel({ from: accounts[1] });
      const review = await cancellableSig.reviewSignatures(
        accounts[1], 0, web3.toHex('data'), 0,
        [ rsv.r ], [ rsv.s ], [ rsv.v ]);
      assert.equal(review.toNumber(), 0);
    });
  });
});
