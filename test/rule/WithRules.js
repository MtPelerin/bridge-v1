'user strict';

const assertRevert = require('../helpers/assertRevert');

var WithRules = artifacts.require('../contracts/rule/WithRules');
var YesNoRule = artifacts.require('../contracts/rule/YesNoRule');

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

    it('should allow owner add a rule', async function () {
      const rule = await YesNoRule.new(true);
      const addReceipt = await withRules.addRule(rule.address);
      assert.equal(addReceipt.logs.length, 1);
      assert.equal(addReceipt.logs[0].event, 'RuleAdded');
      assert.equal(addReceipt.logs[0].args.ruleId, 0);
    });

    it('should not allow owner to add 0 rule', async function () {
      const address = '0x0000000000000000000000000000000000000000';
      await assertRevert(withRules.addRule(address));
    });

    it('should not allow non owner to add a rule', async function () {
      const rule = await YesNoRule.new(true);
      await assertRevert(withRules.addRule(rule.address, { from: accounts[1] }));
    });

    it('should allow owner to add many rules', async function () {
      const rule1 = await YesNoRule.new(true);
      const rule2 = await YesNoRule.new(false);
      const rule3 = await YesNoRule.new(true);
      const rules = [ rule1.address, rule2.address, rule3.address ];
      const addReceipt = await withRules.addManyRules(rules);
      assert.equal(addReceipt.logs.length, 3);
      assert.equal(addReceipt.logs[0].event, 'RuleAdded');
      assert.equal(addReceipt.logs[0].args.ruleId.toNumber(), 0, 'rule1');
      assert.equal(addReceipt.logs[1].event, 'RuleAdded');
      assert.equal(addReceipt.logs[1].args.ruleId.toNumber(), 1, 'rule2');
      assert.equal(addReceipt.logs[2].event, 'RuleAdded');
      assert.equal(addReceipt.logs[2].args.ruleId.toNumber(), 2, 'rule3');
    });

    it('should not allow owner to add 0 rules', async function () {
      const rules = [ ];
      await assertRevert(withRules.addManyRules(rules));
    });

    it('should not allow non owner to add many rules', async function () {
      const rule1 = await YesNoRule.new(true);
      const rule2 = await YesNoRule.new(false);
      const rule3 = await YesNoRule.new(true);
      const rules = [ rule1.address, rule2.address, rule3.address ];
      await assertRevert(withRules.addManyRules(rules, { from: accounts[1] }));
    });

    it('should revert when removing a rule', async function () {
      await assertRevert(withRules.removeRule(0));
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

    it('should only accept a new rule from its creator', async function () {
      const rule2 = await YesNoRule.new(true);
      await assertRevert(withRules.addRule(rule2.address, { from: accounts[1] }));
    });

    it('should only remove a rule from its creator', async function () {
      await assertRevert(withRules.removeRule(0, { from: accounts[1] }));
    });

    it('should allow owner to add a rule', async function () {
      const rule2 = await YesNoRule.new(true);
      const addReceipt = await withRules.addRule(rule2.address);
      assert.equal(addReceipt.logs.length, 1);
      assert.equal(addReceipt.logs[0].event, 'RuleAdded');
      assert.equal(addReceipt.logs[0].args.ruleId, 1);
    });

    it('should allow owner to remove a rule', async function () {
      const removeReceipt = await withRules.removeRule(0);
      assert.equal(removeReceipt.logs.length, 1);
      assert.equal(removeReceipt.logs[0].event, 'RuleRemoved');
      assert.equal(removeReceipt.logs[0].args.ruleId, 0);
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
      await withRules.removeRule(0);
      assert.equal((await withRules.ruleLength()).toNumber(), 0, 'No rules');
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validateTransfer');
    });
  });

  describe('with 2 Yes rules', function () {
    let rule1;
    let rule2;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(true);
      rule2 = await YesNoRule.new(true);
      withRules = await WithRules.new([rule1.address, rule2.address]);
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
      await withRules.addRule(rule3.address);
      assert.equal((await withRules.ruleLength()).toNumber(), 3, 'three rules');
      assert.equal(await withRules.rule(2), rule3.address, 'rule3');
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });
  });

  describe('with one Yes rule and a No rule', function () {
    let rule1;
    let rule2;

    beforeEach(async function () {
      rule1 = await YesNoRule.new(true);
      rule2 = await YesNoRule.new(false);
      withRules = await WithRules.new([rule1.address, rule2.address]);
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
      await withRules.removeRule(1);
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(validateTransfer, 'validate transfer');
    });

    it('should not validate transfer when removing the Yes rule', async function () {
      await withRules.removeRule(0);
      const validateTransfer = await withRules.validateTransfer(accounts[1], accounts[2], 0);
      assert.ok(!validateTransfer, 'not validate transfer');
    });
  });
});
