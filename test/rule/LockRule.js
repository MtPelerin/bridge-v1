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
const LockRule = artifacts.require('../../contracts/rule/LockRule.sol');

contract('LockRule', function (accounts) {
  let rule;
 
  const NONE = 0;
  const RECEIVE = 1;
  const SEND = 2;
  const BOTH = 3;
  const authority = accounts[1];
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;
  const dayMinusOneTime = Math.floor((new Date()).getTime() / 1000) - 3600 * 24;

  beforeEach(async function () {
    rule = await LockRule.new();
    await rule.defineAuthority('OPERATOR', authority);
  });

  async function isAddressValid (address, expected) {
    const isAddressValid = await rule.isAddressValid(address);
    assert.ok(isAddressValid === expected, 'valid');
  };

  async function isTransferValid (sender, receiver, expected) {
    const isTransferValid = await rule.isTransferValid(sender, receiver, 100);
    assert.ok(isTransferValid === expected, 'valid');
  };

  it('should return no startAt', async function () {
    const startAt = await rule.scheduleStartAt();
    assert.equal(startAt.toNumber(), 0, 'startAt');
  });

  it('should return no startAt', async function () {
    const endAt = await rule.scheduleEndAt();
    assert.equal(endAt.toNumber(), 0, 'endAt');
  });

  it('should return default lockActive', async function () {
    const lockActive = await rule.lockActive();
    assert.equal(lockActive.toNumber(), NONE, 'lockActive');
  });

  it('should return default lockInactive', async function () {
    const lockInactive = await rule.lockInactive();
    assert.equal(lockInactive.toNumber(), NONE, 'lockInactive');
  });

  it('should return current lock', async function () {
    const currentLock = await rule.currentLock();
    assert.equal(currentLock.toNumber(), NONE, 'lock');
  });

  it('should return default individual pass', async function () {
    const individualPass = await rule.individualPass(accounts[1]);
    assert.equal(individualPass.toNumber(), NONE, 'individual pass');
  });

  it('should return default canSend', async function () {
    const canSend = await rule.canSend(accounts[0]);
    assert.ok(canSend, 'canSend');
  });

  it('should return default canReceive', async function () {
    const canReceive = await rule.canReceive(accounts[0]);
    assert.ok(canReceive, 'canReceive');
  });

  it('should let operator provide pass to an address', async function () {
    const tx = await rule.definePass(accounts[2], BOTH, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'Pass');
    assert.equal(tx.logs[0].args._address, accounts[2]);
    assert.equal(tx.logs[0].args.lock, BOTH);
  });

  it('should prevent non operator to define pass', async function () {
    await assertRevert(rule.definePass(accounts[2], BOTH));
  });

  it('should let operator to define many passes', async function () {
    const tx = await rule.defineManyPasses([ accounts[2], accounts[3] ], BOTH, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'Pass');
    assert.equal(tx.logs[0].args._address, accounts[2]);
    assert.equal(tx.logs[0].args.lock, BOTH);
    assert.equal(tx.logs[1].event, 'Pass');
    assert.equal(tx.logs[1].args._address, accounts[3]);
    assert.equal(tx.logs[1].args.lock, BOTH);
  });

  it('should prevent non operator to define many passes', async function () {
    await assertRevert(
      rule.defineManyPasses([ accounts[2], accounts[3] ], BOTH));
  });

  it('should let operator to define lock with startAt=endAt', async function () {
    const tx = await rule.defineLock(dayPlusOneTime, dayPlusOneTime, RECEIVE, SEND, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'LockDefinition');
    assert.equal(tx.logs[0].args.startAt, dayPlusOneTime);
    assert.equal(tx.logs[0].args.endAt, dayPlusOneTime);
    assert.equal(tx.logs[0].args.active, RECEIVE);
    assert.equal(tx.logs[0].args.inactive, SEND);
  });

  it('should let operator to define lock', async function () {
    const tx = await rule.defineLock(dayMinusOneTime, dayPlusOneTime, BOTH, BOTH, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'LockDefinition');
    assert.equal(tx.logs[0].args.startAt.toNumber(), dayMinusOneTime);
    assert.equal(tx.logs[0].args.endAt.toNumber(), dayPlusOneTime);
    assert.equal(tx.logs[0].args.active.toNumber(), BOTH);
    assert.equal(tx.logs[0].args.inactive.toNumber(), BOTH);
  });

  it('should prevent non operator to define lock', async function () {
    await assertRevert(
      rule.defineLock(dayMinusOneTime, dayPlusOneTime, BOTH, BOTH));
  });

  describe('with a lock BOTH active and NONE inactive', async function () {
    beforeEach(async function () {
      await rule.defineLock(dayMinusOneTime, dayPlusOneTime, BOTH, NONE, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return lockActive', async function () {
      const lockActive = await rule.lockActive();
      assert.equal(lockActive.toNumber(), BOTH, 'lockActive');
    });

    it('should return lockInactive', async function () {
      const lockInactive = await rule.lockInactive();
      assert.equal(lockInactive.toNumber(), NONE, 'lockInactive');
    });

    it('should return current lock', async function () {
      const currentLock = await rule.currentLock();
      assert.equal(currentLock.toNumber(), BOTH, 'lock');
    });
  });

  describe('with a lock BOTH inactive and NONE active', async function () {
    beforeEach(async function () {
      await rule.defineLock(dayMinusOneTime, dayMinusOneTime, NONE, BOTH, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return default lockActive', async function () {
      const lockActive = await rule.lockActive();
      assert.equal(lockActive.toNumber(), NONE, 'lockActive');
    });

    it('should return default lockInactive', async function () {
      const lockInactive = await rule.lockInactive();
      assert.equal(lockInactive.toNumber(), BOTH, 'lockInactive');
    });

    it('should return default currentLock', async function () {
      const currentLock = await rule.currentLock();
      assert.equal(currentLock.toNumber(), BOTH, 'lock');
    });
  });

  describe('with a lock RECEIVE active and NONE inactive', async function () {
    beforeEach(async function () {
      await rule.defineLock(dayMinusOneTime, dayPlusOneTime, RECEIVE, NONE, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return default lockActive', async function () {
      const lockActive = await rule.lockActive();
      assert.equal(lockActive.toNumber(), RECEIVE, 'lockActive');
    });

    it('should return default lockInactive', async function () {
      const lockInactive = await rule.lockInactive();
      assert.equal(lockInactive.toNumber(), NONE, 'lockInactive');
    });

    it('should return current lock', async function () {
      const currentLock = await rule.currentLock();
      assert.equal(currentLock.toNumber(), RECEIVE, 'lock');
    });
  });

  describe('with a lock SEND active and NONE INACTIVE', async function () {
    beforeEach(async function () {
      await rule.defineLock(dayMinusOneTime, dayPlusOneTime, SEND, NONE, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(canReceive, 'canReceive');
    });

    it('should return lockActive', async function () {
      const lockActive = await rule.lockActive();
      assert.equal(lockActive.toNumber(), SEND, 'lockActive');
    });

    it('should return lockInactive', async function () {
      const lockInactive = await rule.lockInactive();
      assert.equal(lockInactive.toNumber(), NONE, 'lockInactive');
    });

    it('should return current lock', async function () {
      const currentLock = await rule.currentLock();
      assert.equal(currentLock.toNumber(), SEND, 'lock');
    });
  });
});
