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
const TokenWithRules = artifacts.require('../contracts/token/TokenWithRulesMock');
const YesNoRule = artifacts.require('../contracts/rule/YesNoRule');

contract('TokenWithRules', function (accounts) {
  let tokenWithRules;

  describe('with no rules', function () {
    beforeEach(async function () {
      tokenWithRules = await TokenWithRules.new([], accounts[0], 10000);
    });

    it('should allow transfer', async function () {
      await tokenWithRules.transfer(accounts[1], 100);
      assert.equal((await tokenWithRules.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
    });

    it('should allow transferFrom', async function () {
      await tokenWithRules.approve(accounts[2], 100);
      await tokenWithRules.transferFrom(accounts[0], accounts[1], 100, { from: accounts[2] });
      assert.equal((await tokenWithRules.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
    });
  });

  describe('with a Yes rule', function () {
    let rule1;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(true);
      tokenWithRules = await TokenWithRules.new([rule1.address], accounts[0], 10000);
    });

    it('should allow transfer', async function () {
      await tokenWithRules.transfer(accounts[1], 100);
      assert.equal((await tokenWithRules.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
    });

    it('should allow transferFrom', async function () {
      await tokenWithRules.approve(accounts[2], 100);
      await tokenWithRules.transferFrom(accounts[0], accounts[1], 100, { from: accounts[2] });
      assert.equal((await tokenWithRules.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
    });
  });

  describe('with a No rule', function () {
    let rule1;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(false);
      tokenWithRules = await TokenWithRules.new([rule1.address], accounts[0], 10000);
      assert.equal((await tokenWithRules.ruleLength()).toNumber(), 1, 'one rule');
      assert.equal(await tokenWithRules.rule(0), rule1.address, 'rule1');
    });

    it('should prevent transfer', async function () {
      await assertRevert(tokenWithRules.transfer(accounts[1], 100));
    });

    it('should prevent transferFrom', async function () {
      await tokenWithRules.approve(accounts[2], 100);
      await assertRevert(
        tokenWithRules.transferFrom(
          accounts[0], accounts[1], 100, { from: accounts[2] }
        ));
    });
  });
});
