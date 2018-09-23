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

const assertRevert = require('../helpers/assertRevert');
const Shareholder = artifacts.require('../contracts/demo/Shareholder.sol');

contract('Shareholder', function (accounts) {
  let shareholder;

  beforeEach(async function () {
    shareholder = await Shareholder.new();
  });

  it('should have no shareholders', async function () {
    const shareholders = await shareholder.shareholders();
    assert.equal(shareholders.length, 0);
  });

  it('should return false for isShareholder', async function () {
    const isShareholder = await shareholder.isShareholder(accounts[1]);
    assert.ok(!isShareholder, 'not shareholder');
  });

  it('should be possible for owner to update shareholders', async function () {
    const tx = await shareholder.updateShareholders([ accounts[1], accounts[2] ]);
    assert.equal(tx.receipt.status, '0x1', 'status');
  });

  it('should not be possible for non owner to update shareholders', async function () {
    await assertRevert(
      shareholder.updateShareholders(
        [ accounts[1], accounts[2] ], { from: accounts[1] }
      )
    );
  });

  describe('with some shareholders', function () {
    beforeEach(async function () {
      await shareholder.updateShareholders([ accounts[1], accounts[2] ]);
    });

    it('should have 2 shareholders', async function () {
      const shareholders = await shareholder.shareholders();
      assert.equal(shareholders.length, 2);
    });

    it('should return true for isShareholder if address is shareholder', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[1]);
      assert.ok(isShareholder, 'is shareholder');
    });

    it('should return false for isShareholder if address is owner', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[0]);
      assert.ok(!isShareholder, 'owner is not shareholder');
    });

    it('should return false for isShareholder if address is non shareholder or non owner', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[5]);
      assert.ok(!isShareholder, 'not shareholder');
    });
  });
});
