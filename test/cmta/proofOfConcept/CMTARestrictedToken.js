'User strict';

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
const CMTARestrictedTokenMock = artifacts.require('../../contracts/cmta/mock/CMTARestrictedTokenMock.sol');

contract('CMTARestrictedToken', function (accounts) {
  let token;

  const hash = '0x000001234578';
  const tomorrow = (new Date().getTime() / 1000) + 24 * 3600;

  beforeEach(async function () {
    token = await CMTARestrictedTokenMock.new(accounts[0], 10 ** 20, hash);
    await token.acceptAgreement(hash, { from: accounts[1] });
  });

  it('should allow transfer from initial account', async function () {
    const tx = await token.transfer(accounts[1], 1000000);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
  });

  it('should allow transferFrom from initial account', async function () {
    const approveTx = await token.approve(accounts[1], 1000000);
    assert.equal(parseInt(approveTx.receipt.status), 1, 'approve status');
    await assertRevert(token.transferFrom(accounts[0], accounts[1], 10000, { from: accounts[1] }));
  });
 
  describe('with initial account KYCed', function () {
    beforeEach(async function () {
      await token.validateKYCUntil(accounts[0], tomorrow);
    });

    it('should not allow transfer from initial account', async function () {
      const tx = await token.transfer(accounts[1], 1000000);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should not allow transferFrom from initial account', async function () {
      await token.approve(accounts[1], 1000000);
      await assertRevert(token.transferFrom(accounts[0], accounts[1], 10000, { from: accounts[1] }));
    });
  });

  describe('with initial account and recipient KYCed', function () {
    beforeEach(async function () {
      await token.validateManyKYCUntil([ accounts[0], accounts[1] ], tomorrow);
    });

    it('should allow transfer from initial account', async function () {
      const tx = await token.transfer(accounts[1], 1000000);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should let initial account approve', async function () {
      const increased = await token.approve(accounts[3], 1000000);
      assert.equal(parseInt(increased.receipt.status), 1, 'increased');
    });

    it('should allow transferFrom from initial account', async function () {
      const increased = await token.approve(accounts[2], 1000000);
      assert.equal(parseInt(increased.receipt.status), 1, 'increased');
      await assertRevert(token.transferFrom(
        accounts[0], accounts[1], 10000, { from: accounts[2] }));
    });
  });

  describe('with initial account, recipient and msg.sender KYCed', function () {
    beforeEach(async function () {
      await token.validateManyKYCUntil([ accounts[0], accounts[1], accounts[2] ], tomorrow);
    });

    it('should allow transferFrom from initial account', async function () {
      const increased = await token.approve(accounts[2], 1000000);
      assert.equal(parseInt(increased.receipt.status), 1, 'increased');
      const tx = await token.transferFrom(
        accounts[0], accounts[1], 10000, { from: accounts[2] });
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });
  });
});
