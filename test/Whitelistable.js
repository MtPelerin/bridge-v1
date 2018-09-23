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

const assertRevert = require('./helpers/assertRevert');
const Whitelist = artifacts.require('../contracts/Whitelist.sol');
const WhitelistableMock = artifacts.require('../contracts/WhitelistableMock.sol');

contract('Whitelistable', function (accounts) {
  let whitelist;
  let whitelistable;

  beforeEach(async function () {
    whitelist = await Whitelist.new([accounts[1], accounts[2]]);
    whitelistable = await WhitelistableMock.new();
  });

  it('should have no whitelist', async function () {
    const whitelistAddr = await whitelistable.whitelist();
    assert.equal(whitelistAddr, '0x0000000000000000000000000000000000000000');
  });

  it('should have a modifier blocking', async function () {
    await assertRevert(whitelistable.testMe());
  });

  it('should update the whitelist', async function () {
    const tx = await whitelistable.updateWhitelist(whitelist.address);
    assert.equal(tx.receipt.status, '0x1', 'Status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'WhitelistUpdated');
    assert.equal(tx.logs[0].args.whitelist, whitelist.address);
  });

  describe('with a whitelist configured', function () {
    beforeEach(async function () {
      await whitelistable.updateWhitelist(whitelist.address);
    });

    it('should returns the whitelist address', async function () {
      const whitelistAddr = await whitelistable.whitelist();
      assert.equal(whitelistAddr, whitelist.address, 'whitelistAddr');
    });

    it('should have the modifier working', async function () {
      const txApprove = await whitelist.approveAddress(accounts[0]);
      assert.equal(txApprove.receipt.status, '0x1', 'Status');
      const txIsWhitelisted = await whitelistable.testMe();
      assert.equal(txIsWhitelisted.receipt.status, '0x1', 'Status');

      const success = await whitelistable.success();
      assert.equal(success, true, 'modifier success');
    });
  });
});
