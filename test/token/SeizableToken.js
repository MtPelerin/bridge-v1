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

const assertThrow = require('../helpers/assertThrow');
const assertRevert = require('../helpers/assertRevert');
const SeizableTokenMock = artifacts.require('./mocks/SeizableTokenMock.sol');

contract('SeizableToken', function (accounts) {
  let token;
  const authority = accounts[2];

  beforeEach(async function () {
    token = await SeizableTokenMock.new(accounts[0], 100);

    await token.transfer(accounts[1], 50);
    const balance0 = await token.balanceOf(accounts[0]);
    assert.equal(balance0, 50);
    const balance1 = await token.balanceOf(accounts[1]);
    assert.equal(balance1, 50);

    const allTimeSeized = await token.allTimeSeized();
    assert.equal(allTimeSeized, 0);
  });

  it('should not allow owner to seize anything', async function () {
    await assertRevert(token.seize(accounts[1], 1));
  });

  it('should not allow any user to seize anything', async function () {
    await assertRevert(token.seize(accounts[0], 1, { from: accounts[1] }));
  });

  describe('with authority defined', function () {
    beforeEach(async function () {
      await token.defineAuthority('REGULATOR', authority);
      const authorityBalance = await token.balanceOf(authority);
      assert.equal(authorityBalance.toNumber(), 0, 'authority balance');
    });

    it('should seize 1 from account', async function () {
      await token.seize(accounts[1], 1, { from: authority });

      const balance0 = await token.balanceOf(accounts[0]);
      assert.equal(balance0.toNumber(), 50, 'balance 0');
      const balance1 = await token.balanceOf(accounts[1]);
      assert.equal(balance1.toNumber(), 49, 'balance 1');
      const authorityBalance = await token.balanceOf(authority);
      assert.equal(authorityBalance.toNumber(), 1, 'authority balance');
     });

    it('should seize everything from account', async function () {
      await token.seize(accounts[1], 50, { from: authority });

      const balance0 = await token.balanceOf(accounts[0]);
      assert.equal(balance0.toNumber(), 50, 'balance 0');
      const balance1 = await token.balanceOf(accounts[1]);
      assert.equal(balance1.toNumber(), 0, 'balance 1');
      const authorityBalance = await token.balanceOf(authority);
      assert.equal(authorityBalance.toNumber(), 50, 'authority balance');
    });

    it('should increase allTimeSeize value', async function () {
      await token.seize(accounts[1], 10, { from: authority });
      const allTimeSeized1 = await token.allTimeSeized();
      assert.equal(allTimeSeized1, 10);

      await token.seize(accounts[1], 10, { from: authority });
      const allTimeSeized2 = await token.allTimeSeized();
      assert.equal(allTimeSeized2, 20);
    });

    it('should log an event when seizing 2', async function () {
      const receipt = await token.seize(accounts[1], 2, { from: authority });
      assert.equal(receipt.logs.length, 1);
      assert.equal(receipt.logs[0].event, 'Seize');
      assert.equal(receipt.logs[0].args.account, accounts[1]);
      assert.equal(receipt.logs[0].args.amount, 2);
    });

    it('should throw an error trying to seize more than account have', async function () {
      await assertThrow(token.seize(accounts[1], 1000, { from: authority }));
    });

    it('should revert trying to seize authority (self)', async function () {
      await assertRevert(token.seize(accounts[0], 1000, { from: authority }));
    });

    it('should not allow anyone other than authority to seize', async function () {
      await assertRevert(token.seize(accounts[1], 1000));
    });
  });
});
