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
const WithRules = artifacts.require('../contracts/rule/WithRules');
const YesNoRule = artifacts.require('../contracts/rule/YesNoRule');

contract('WithRules', function (accounts) {
  let withRules;

  describe('with no rules', function () {
    beforeEach(async function () {
      withRules = await WithRules.new([]);
    });

    it('should have a length', async function () {
      const length = await withRules.ruleLength();
      assert.equal(length, 0, 'length');
    });

    it('should validateAddress', async function () {
      const validateAddress = await withRules.validateAddress(accounts[1]);
      assert.ok(validateAddress, 'validateAddress');
    });

    it('should validateTransfer', async function () {
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validateTransfer');
    });

    it('should allow owner to defines rules', async function () {
      const rule1 = await YesNoRule.new(true);
      const rule2 = await YesNoRule.new(false);
      const rule3 = await YesNoRule.new(true);
      const rules = [ rule1.address, rule2.address, rule3.address ];
      const addReceipt = await withRules.defineRules(rules);
      assert.equal(addReceipt.logs.length, 1);
      assert.equal(addReceipt.logs[0].event, 'RulesDefined');
      assert.equal(addReceipt.logs[0].args.count.toNumber(), 3, 'rulesDefined');
    });

    it('should not allow non owner to define rules', async function () {
      const rule = await YesNoRule.new(true);
      await assertRevert(withRules.defineRules([ rule.address ], { from: accounts[1] }));
    });
  });

  describe('with a Yes rule', function () {
    let rule1;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(true);
      withRules = await WithRules.new([rule1.address]);
    });

    it('should validateAddress', async function () {
      const validateAddress = await withRules.validateAddress(accounts[1]);
      assert.ok(validateAddress, 'validateAddress');
    });

    it('should validateTransfer', async function () {
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validateTransfer');
    });

    it('should have one rule', async function () {
      const length = await withRules.ruleLength();
      assert.equal(length.toNumber(), 1, 'one rule');
    });

    it('should have the Yes rule with ruleId 1', async function () {
      const ruleAddress = await withRules.rule(0);
      assert.equal(ruleAddress, rule1.address, 'rule address');
    });

    it('should allow to redefine rules', async function () {
      const rule2 = await YesNoRule.new(true);
      const addReceipt = await withRules.defineRules([ rule1.address, rule2.address ]);
      assert.equal(addReceipt.logs.length, 1);
      assert.equal(addReceipt.logs[0].event, 'RulesDefined');
      assert.equal(addReceipt.logs[0].args.count.toNumber(), 2);
    });
  });

  describe('with a No rule', function () {
    let rule1;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(false);
      withRules = await WithRules.new([rule1.address]);
      assert.equal((await withRules.ruleLength()).toNumber(), 1, 'one rule');
      assert.equal(await withRules.rule(0), rule1.address, 'rule1');
    });

    it('should validateAddress', async function () {
      const validateAddress = await withRules.validateAddress(accounts[1]);
      assert.ok(!validateAddress, 'validateAddress');
    });

    it('should not validate transfer', async function () {
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });

    it('should validate transfer when removing the No rule', async function () {
      await withRules.defineRules([]);
      assert.equal((await withRules.ruleLength()).toNumber(), 0, 'No rules');
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validateTransfer');
    });
  });

  describe('with 2 Yes rules', function () {
    let rules;

    beforeEach(async function () {
      let rule1 = await YesNoRule.new(true);
      let rule2 = await YesNoRule.new(true);
      rules = [ rule1.address, rule2.address ];
      withRules = await WithRules.new(rules);
      assert.equal((await withRules.ruleLength()).toNumber(), 2, 'two rules');
      assert.equal(await withRules.rule(0), rule1.address, 'rule1');
      assert.equal(await withRules.rule(1), rule2.address, 'rule2');
    });

    it('should validateAddress', async function () {
      const validateAddress = await withRules.validateAddress(accounts[1]);
      assert.ok(validateAddress, 'validateAddress');
    });

    it('should validate transfer', async function () {
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validate transfer');
    });

    it('should not validate transfer when adding a No rule', async function () {
      const rule3 = await YesNoRule.new(false);
      rules.push(rule3.address);
      await withRules.defineRules(rules);
      assert.equal((await withRules.ruleLength()).toNumber(), 3, 'three rules');
      assert.equal(await withRules.rule(2), rule3.address, 'rule3');
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });
  });

  describe('with one Yes rule and a No rule', function () {
    let rules;

    beforeEach(async function () {
      let rule1 = await YesNoRule.new(true);
      let rule2 = await YesNoRule.new(false);
      rules = [ rule1.address, rule2.address ];
      withRules = await WithRules.new(rules);
      assert.equal((await withRules.ruleLength()).toNumber(), 2, 'two rules');
      assert.equal(await withRules.rule(0), rule1.address);
      assert.equal(await withRules.rule(1), rule2.address);
    });

    it('should validateAddress', async function () {
      const validateAddress = await withRules.validateAddress(accounts[1]);
      assert.ok(!validateAddress, 'validateAddress');
    });

    it('should not validate transfer', async function () {
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });

    it('should validate transfer when removing the No rule', async function () {
      await withRules.defineRules([ rules[0] ]);
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validate transfer');
    });

    it('should not validate transfer when removing the Yes rule', async function () {
      await withRules.defineRules([ rules[1] ]);
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });
  });
});
