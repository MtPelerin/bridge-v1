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
const UserRegistry = artifacts.require('../../contracts/UserRegistry.sol');
const StandardToken = artifacts.require('../../contracts/mock/StandardTokenMock.sol');
const StrategicInvestorsRule = artifacts.require('../../contracts/rule/StrategicInvestorsRule.sol');

contract('StrategicInvestorsRule', function (accounts) {
  let rule, token, userRegistry;
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;
  const userAddresses = [ accounts[0], accounts[1], accounts[2], accounts[3], accounts[4], accounts[5] ];

  beforeEach(async function () {
    token = await StandardToken.new(accounts[0], 100000);
    userRegistry = await UserRegistry.new(userAddresses, dayPlusOneTime);
    rule = await StrategicInvestorsRule.new(
      userRegistry.address,
      token.address, 100, [ 1, 2, 3 ]); // accounts 0, 1 and 2
  });

  async function isTransferValid (sender, receiver, amount, expected, message) {
    const isTransferValid = await rule.isTransferValid(sender, receiver, amount);
    assert.ok(isTransferValid === expected, message);
  }

  it('should returns the strategic threshold', async function () {
    const strategicThreshold = await rule.strategicThreshold();
    assert.equal(strategicThreshold, 100, 'strategic threshold');
  });

  it('should let owner update the strategic threshold', async function () {
    const tx = await rule.updateStrategicThreshold(200);
    assert.equal(tx.logs.length, 1, 'logs');
    assert.equal(tx.logs[0].event, 'StrategicThresholdUpdated', 'log name');
    assert.equal(tx.logs[0].args.strategicThreshold, 200, 'strategicThreshold');
  });

  it('should prevent non owner to update the strategic threshold', async function () {
    await assertRevert(rule.updateStrategicThreshold(200, { from: accounts[1] }));
  });

  it('should returns the token', async function () {
    const tokenAddress = await rule.token();
    assert.equal(tokenAddress, token.address, 'tokenAddress');
  });

  it('should returns the userRegistry', async function () {
    const userRegistryAddress = await rule.userRegistry();
    assert.equal(userRegistryAddress, userRegistry.address, 'userRegistry');
  });

  it('should returns that account 0 is strategic', async function () {
    const isStrategic = await rule.isStrategicInvestor(1);
    assert.ok(isStrategic, 'isStrategic');
  });

  it('should returns that account 3 is not strategic', async function () {
    const isStrategic = await rule.isStrategicInvestor(4);
    assert.ok(!isStrategic, '!isStrategic');
  });

  it('should update a strategic investor', async function () {
    const tx = await rule.updateStrategicInvestor(4, true);
    assert.equal(tx.logs.length, 1, 'logs');
    assert.equal(tx.logs[0].event, 'StrategicInvestorUpdated', 'log name');
    assert.equal(tx.logs[0].args.userId, 4, 'userId');
    assert.equal(tx.logs[0].args.status, true, 'status');

    const isStrategic = await rule.isStrategicInvestor(4);
    assert.ok(isStrategic, 'isStrategic');
  });

  it('should update many strategic investors', async function () {
    const tx = await rule.updateManyStrategicInvestors([4, 5], true);
    assert.equal(tx.logs.length, 2, 'logs');
    assert.equal(tx.logs[0].event, 'StrategicInvestorUpdated', 'log name');
    assert.equal(tx.logs[0].args.userId, 4, 'userId');
    assert.equal(tx.logs[0].args.status, true, 'status');
    assert.equal(tx.logs[1].event, 'StrategicInvestorUpdated', 'log name');
    assert.equal(tx.logs[1].args.userId, 5, 'userId');
    assert.equal(tx.logs[1].args.status, true, 'status');

    const isStrategic4 = await rule.isStrategicInvestor(4);
    assert.ok(isStrategic4, 'isStrategic4');
    const isStrategic5 = await rule.isStrategicInvestor(5);
    assert.ok(isStrategic5, 'isStrategic5');
  });

  describe('when receiving', function () {
    beforeEach(async function () {
      await token.transfer(accounts[1], 2000);
      await token.transfer(accounts[2], 95);
      await token.transfer(accounts[3], 20);
      await token.transfer(accounts[4], 95);
    });

    it('should be valid below strategic investment threshold for a non strategic investor', async function () {
      await isTransferValid(accounts[0], accounts[4], 4, true, 'sender is strategic');
      await isTransferValid(accounts[3], accounts[4], 4, true, 'sender is not strategic');
    });

    it('should be valid below strategic investment threshold for strategic investor', async function () {
      await isTransferValid(accounts[0], accounts[2], 10, true, 'sender is strategic');
      await isTransferValid(accounts[3], accounts[2], 10, true, 'sender is not strategic');
    });

    it('should be valid above or equal to strategic investment threshold for strategic investors', async function () {
      await isTransferValid(accounts[0], accounts[2], 5, true, 'sender is strategic && equal threshold');
      await isTransferValid(accounts[3], accounts[2], 5, true, 'sender is not strategic && equal threshold');
      await isTransferValid(accounts[0], accounts[2], 10, true, 'sender is strategic && above threshold');
      await isTransferValid(accounts[3], accounts[2], 10, true, 'sender is not strategic && above threshold');
    });

    it('should be invalid above or equal to strategic investment threshold for non strategic investors',
      async function () {
        await isTransferValid(accounts[0], accounts[4], 5, false, 'sender is strategic && equal threshold');
        await isTransferValid(accounts[3], accounts[4], 5, false, 'sender is not strategic && equal threshold');
        await isTransferValid(accounts[0], accounts[4], 10, false, 'sender is strategic && above threshold');
        await isTransferValid(accounts[3], accounts[4], 10, false, 'sender is not strategic && above threshold');
      });
  });

  describe('when sending', function () {
    beforeEach(async function () {
      await token.transfer(accounts[1], 2000);
      await token.transfer(accounts[2], 95);
      await token.transfer(accounts[3], 20);
      await token.transfer(accounts[4], 95);
      await token.transfer(accounts[5], 150);
    });

    it('should be valid below strategic investment threshold for a non strategic investor', async function () {
      await isTransferValid(accounts[4], accounts[0], 10, true, 'receiver is strategic');
      await isTransferValid(accounts[4], accounts[3], 10, true, 'receiver is not strategic');
    });

    it('should be valid below strategic investment threshold for strategic investor', async function () {
      await isTransferValid(accounts[2], accounts[0], 10, true, 'receiver is strategic');
      await isTransferValid(accounts[2], accounts[3], 10, true, 'receiver is not strategic');
    });

    it('should be valid above to strategic investment threshold for strategic investors', async function () {
      await isTransferValid(accounts[1], accounts[0], 10, true, 'receiver is strategic && above threshold');
      await isTransferValid(accounts[1], accounts[3], 10, true, 'receiver is not strategic && above threshold');
    });

    it('should be valid above to strategic investment threshold for non strategic investors', async function () {
      await isTransferValid(accounts[5], accounts[0], 10, true, 'sender is strategic && above threshold');
      await isTransferValid(accounts[5], accounts[3], 10, true, 'sender is not strategic && above threshold');
    });
  });
});
