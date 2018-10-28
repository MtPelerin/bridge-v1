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

  it('should not have receive direction for none', async function () {
    const hasReceiveDirection = await rule.hasReceiveDirection(NONE);
    assert.ok(!hasReceiveDirection, 'hasReceiveDirection');
  });

  it('should have receive direction for receive', async function () {
    const hasReceiveDirection = await rule.hasReceiveDirection(RECEIVE);
    assert.ok(hasReceiveDirection, 'hasReceiveDirection');
  });

  it('should not have receive direction for send', async function () {
    const hasReceiveDirection = await rule.hasReceiveDirection(SEND);
    assert.ok(!hasReceiveDirection, 'hasReceiveDirection');
  });

  it('should have send direction for both', async function () {
    const hasReceiveDirection = await rule.hasReceiveDirection(BOTH);
    assert.ok(hasReceiveDirection, 'hasReceiveDirection');
  });

  it('should not have send direction for none', async function () {
    const hasSendDirection = await rule.hasSendDirection(NONE);
    assert.ok(!hasSendDirection, 'hasSendDirection');
  });

  it('should not have send direction for receive', async function () {
    const hasSendDirection = await rule.hasSendDirection(RECEIVE);
    assert.ok(!hasSendDirection, 'hasSendDirection');
  });

  it('should have send direction for send', async function () {
    const hasSendDirection = await rule.hasSendDirection(SEND);
    assert.ok(hasSendDirection, 'hasSendDirection');
  });

  it('should have send direction for both', async function () {
    const hasSendDirection = await rule.hasSendDirection(BOTH);
    assert.ok(hasSendDirection, 'hasSendDirection');
  });

  it('should return restriction', async function () {
    const restriction = await rule.restriction();
    assert.equal(restriction, NONE, 'restriction');
  });

  it('should return no startAt', async function () {
    const startAt = await rule.scheduledStartAt();
    assert.equal(startAt.toNumber(), 0, 'startAt');
  });

  it('should return no startAt', async function () {
    const endAt = await rule.scheduledEndAt();
    assert.equal(endAt.toNumber(), 0, 'endAt');
  });

  it('should return schedule inverted', async function () {
    const scheduleInverted = await rule.isScheduleInverted();
    assert.ok(!scheduleInverted, 'scheduleInverted');
  });

  it('should return current lock', async function () {
    const isLocked = await rule.isLocked();
    assert.ok(!isLocked, 'lock');
  });

  it('should return individual pass', async function () {
    const individualPass = await rule.individualPass(accounts[1]);
    assert.equal(individualPass.toNumber(), NONE, 'individual pass');
  });

  it('should return canSend', async function () {
    const canSend = await rule.canSend(accounts[0]);
    assert.ok(canSend, 'canSend');
  });

  it('should return canReceive', async function () {
    const canReceive = await rule.canReceive(accounts[0]);
    assert.ok(canReceive, 'canReceive');
  });

  it('should let operator provide pass to an address', async function () {
    const tx = await rule.definePass(accounts[2], BOTH, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'PassDefinition');
    assert.equal(tx.logs[0].args._address, accounts[2]);
    assert.equal(tx.logs[0].args.pass, BOTH);
  });

  it('should prevent non operator to define pass', async function () {
    await assertRevert(rule.definePass(accounts[2], BOTH));
  });

  it('should let operator to define many passes', async function () {
    const tx = await rule.defineManyPasses([ accounts[2], accounts[3] ], BOTH, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'PassDefinition');
    assert.equal(tx.logs[0].args._address, accounts[2]);
    assert.equal(tx.logs[0].args.pass, BOTH);
    assert.equal(tx.logs[1].event, 'PassDefinition');
    assert.equal(tx.logs[1].args._address, accounts[3]);
    assert.equal(tx.logs[1].args.pass, BOTH);
  });

  it('should prevent non operator to define many passes', async function () {
    await assertRevert(
      rule.defineManyPasses([ accounts[2], accounts[3] ], BOTH));
  });

  it('should prevent operator to schedule lock with startAt>endAt', async function () {
    await assertRevert(rule.scheduleLock(BOTH,
      dayPlusOneTime, dayMinusOneTime, true, { from: accounts[1] }));
  });

  it('should let operator to schedule lock with startAt=endAt', async function () {
    const tx = await rule.scheduleLock(BOTH,
      dayPlusOneTime, dayPlusOneTime, true, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'LockDefinition');
    assert.equal(tx.logs[0].args.startAt, dayPlusOneTime);
    assert.equal(tx.logs[0].args.endAt, dayPlusOneTime);
    assert.equal(tx.logs[0].args.scheduleInverted, true);
  });

  it('should let operator to schedule lock', async function () {
    const tx = await rule.scheduleLock(BOTH,
      dayMinusOneTime, dayPlusOneTime, true, { from: accounts[1] });
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'LockDefinition');
    assert.equal(tx.logs[0].args.startAt.toNumber(), dayMinusOneTime);
    assert.equal(tx.logs[0].args.endAt.toNumber(), dayPlusOneTime);
    assert.equal(tx.logs[0].args.scheduleInverted, true);
  });

  it('should prevent non operator to define lock', async function () {
    await assertRevert(
      rule.scheduleLock(BOTH, dayMinusOneTime, dayPlusOneTime, true));
  });

  it('should return true for isAddressValid', async function () {
    const valid = rule.isAddressValid(accounts[2]);
    assert.ok(valid, 'address valid');
  });

  it('should return true for isTransferValid', async function () {
    const valid = rule.isTransferValid(accounts[2], accounts[3], 100);
    assert.ok(valid, 'transfer valid');
  });

  describe('with a lock BOTH active non inverted', async function () {
    beforeEach(async function () {
      await rule.scheduleLock(BOTH,
        dayMinusOneTime, dayPlusOneTime, false, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return lockInverted', async function () {
      const scheduleInverted = await rule.isScheduleInverted();
      assert.ok(!scheduleInverted, 'scheduleInverted');
    });

    it('should return current lock', async function () {
      const isLocked = await rule.isLocked();
      assert.ok(isLocked, 'lock');
    });

    it('should return true for isTransferValid', async function () {
      const valid = rule.isTransferValid(accounts[2], accounts[3], 100);
      assert.ok(valid, 'transfer valid');
    });

    describe('with a pass RECEIVE,SEND and BOTH', function () {
      beforeEach(async function () {
        await rule.definePass(accounts[2], RECEIVE, { from: accounts[1] });
        await rule.definePass(accounts[3], SEND, { from: accounts[1] });
        await rule.definePass(accounts[4], BOTH, { from: accounts[1] });
      });

      it('should not be able to send with a RECEIVE pass', async function () {
        const canSend = await rule.canSend(accounts[2]);
        assert.ok(!canSend, 'canSend');
      });

      it('should be able to receive with a RECEIVE pass', async function () {
        const canReceive = await rule.canReceive(accounts[2]);
        assert.ok(canReceive, 'canReceive');
      });
 
      it('should be able to send with a SEND pass', async function () {
        const canSend = await rule.canSend(accounts[3]);
        assert.ok(canSend, 'canSend');
      });

      it('should not be able to receive with a SEND pass', async function () {
        const canReceive = await rule.canReceive(accounts[3]);
        assert.ok(!canReceive, 'canReceive');
      });
 
      it('should be able to send with a BOTH pass', async function () {
        const canSend = await rule.canSend(accounts[4]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a BOTH pass', async function () {
        const canReceive = await rule.canReceive(accounts[4]);
        assert.ok(canReceive, 'canReceive');
      });

      it('should return true for isTransferValid', async function () {
        const valid = rule.isTransferValid(accounts[2], accounts[3], 100);
        assert.ok(valid, 'transfer valid');
      });

      it('should return true for isTransferValid', async function () {
        const valid = rule.isTransferValid(accounts[2], accounts[4], 100);
        assert.ok(valid, 'transfer valid');
      });

      it('should return true for isTransferValid', async function () {
        const valid = rule.isTransferValid(accounts[4], accounts[3], 100);
        assert.ok(valid, 'transfer valid');
      });
    });
  });

  describe('with a lock inactive inverted', async function () {
    beforeEach(async function () {
      await rule.scheduleLock(BOTH,
        dayMinusOneTime, dayMinusOneTime, true, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return lockInverted', async function () {
      const scheduleInverted = await rule.isScheduleInverted();
      assert.ok(scheduleInverted, 'scheduleInverted');
    });

    it('should return current lock', async function () {
      const isLocked = await rule.isLocked();
      assert.ok(isLocked, 'lock');
    });

    describe('with a pass RECEIVE,SEND and BOTH', function () {
      beforeEach(async function () {
        await rule.definePass(accounts[2], RECEIVE, { from: accounts[1] });
        await rule.definePass(accounts[3], SEND, { from: accounts[1] });
        await rule.definePass(accounts[4], BOTH, { from: accounts[1] });
      });

      it('should not be able to send with a RECEIVE pass', async function () {
        const canSend = await rule.canSend(accounts[2]);
        assert.ok(!canSend, 'canSend');
      });

      it('should be able to receive with a RECEIVE pass', async function () {
        const canReceive = await rule.canReceive(accounts[2]);
        assert.ok(canReceive, 'canReceive');
      });
 
      it('should be able to send with a SEND pass', async function () {
        const canSend = await rule.canSend(accounts[3]);
        assert.ok(canSend, 'canSend');
      });

      it('should not be able to receive with a SEND pass', async function () {
        const canReceive = await rule.canReceive(accounts[3]);
        assert.ok(!canReceive, 'canReceive');
      });
 
      it('should be able to send with a BOTH pass', async function () {
        const canSend = await rule.canSend(accounts[4]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a BOTH pass', async function () {
        const canReceive = await rule.canReceive(accounts[4]);
        assert.ok(canReceive, 'canReceive');
      });
    });
  });

  describe('with a lock RECEIVE active', async function () {
    beforeEach(async function () {
      await rule.scheduleLock(RECEIVE,
        dayMinusOneTime, dayPlusOneTime, false, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(!canReceive, 'canReceive');
    });

    it('should return current lock', async function () {
      const isLocked = await rule.isLocked();
      assert.ok(isLocked, 'lock');
    });

    describe('with a pass RECEIVE,SEND and BOTH', function () {
      beforeEach(async function () {
        await rule.definePass(accounts[2], RECEIVE, { from: accounts[1] });
        await rule.definePass(accounts[3], SEND, { from: accounts[1] });
        await rule.definePass(accounts[4], BOTH, { from: accounts[1] });
      });

      it('should be able to send with a RECEIVE pass', async function () {
        const canSend = await rule.canSend(accounts[2]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a RECEIVE pass', async function () {
        const canReceive = await rule.canReceive(accounts[2]);
        assert.ok(canReceive, 'canReceive');
      });
 
      it('should be able to send with a SEND pass', async function () {
        const canSend = await rule.canSend(accounts[3]);
        assert.ok(canSend, 'canSend');
      });

      it('should not be able to receive with a SEND pass', async function () {
        const canReceive = await rule.canReceive(accounts[3]);
        assert.ok(!canReceive, 'canReceive');
      });
 
      it('should be able to send with a BOTH pass', async function () {
        const canSend = await rule.canSend(accounts[4]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a BOTH pass', async function () {
        const canReceive = await rule.canReceive(accounts[4]);
        assert.ok(canReceive, 'canReceive');
      });
    });
  });

  describe('with a lock SEND active', async function () {
    beforeEach(async function () {
      await rule.scheduleLock(SEND,
        dayMinusOneTime, dayPlusOneTime, false, { from: accounts[1] });
    });

    it('canSend', async function () {
      const canSend = await rule.canSend(accounts[0]);
      assert.ok(!canSend, 'canSend');
    });

    it('canReceive', async function () {
      const canReceive = await rule.canReceive(accounts[0]);
      assert.ok(canReceive, 'canReceive');
    });

    it('should return current lock', async function () {
      const isLocked = await rule.isLocked();
      assert.ok(isLocked, 'lock');
    });

    describe('with a pass RECEIVE,SEND and BOTH', function () {
      beforeEach(async function () {
        await rule.definePass(accounts[2], RECEIVE, { from: accounts[1] });
        await rule.definePass(accounts[3], SEND, { from: accounts[1] });
        await rule.definePass(accounts[4], BOTH, { from: accounts[1] });
      });

      it('should not be able to send with a RECEIVE pass', async function () {
        const canSend = await rule.canSend(accounts[2]);
        assert.ok(!canSend, 'canSend');
      });

      it('should be able to receive with a RECEIVE pass', async function () {
        const canReceive = await rule.canReceive(accounts[2]);
        assert.ok(canReceive, 'canReceive');
      });
 
      it('should be able to send with a SEND pass', async function () {
        const canSend = await rule.canSend(accounts[3]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a SEND pass', async function () {
        const canReceive = await rule.canReceive(accounts[3]);
        assert.ok(canReceive, 'canReceive');
      });
 
      it('should be able to send with a BOTH pass', async function () {
        const canSend = await rule.canSend(accounts[4]);
        assert.ok(canSend, 'canSend');
      });

      it('should be able to receive with a BOTH pass', async function () {
        const canReceive = await rule.canReceive(accounts[4]);
        assert.ok(canReceive, 'canReceive');
      });
    });
  });
});
