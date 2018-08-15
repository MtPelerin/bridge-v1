'user strict';

const assertRevert = require('../helpers/assertRevert');

var TokenWithRules = artifacts.require('../contracts/token/TokenWithRulesMock');
var YesNoRule = artifacts.require('../contracts/rule/YesNoRule');

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
