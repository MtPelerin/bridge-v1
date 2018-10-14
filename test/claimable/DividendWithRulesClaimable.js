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

const TokenWithClaims = artifacts.require('./contracts/mock/TokenWithClaimsMock.sol');
const DividendWithRulesClaimable = artifacts.require('./contracts/dividend/DividendWithRulesClaimable.sol');

contract('DividendWithRulesClaimable', function (accounts) {
  let dividendWithRuleClaimable;
  let token;

  const delay = 1;
  async function waitDelay () {
    await new Promise(resolve => setTimeout(resolve, (delay + 1) * 1000));
  }

  const before = Math.floor((new Date()).getTime() / 1000);
 
  beforeEach(async function () {
    token = await TokenWithClaims.new([], accounts[0], 10000);
    await token.transfer(accounts[1], 200);
    dividendWithRuleClaimable = await DividendWithRulesClaimable.new(token.address, []);
    await token.defineClaimables([ dividendWithRuleClaimable.address ]);
  });

  it('should have no claims', async function () {
    const hasClaims = await dividendWithRuleClaimable.hasClaimsSince(accounts[1], before);
    assert.ok(!hasClaims, 'hasClaims');
  });

  describe('with a past dividend', function () {
    beforeEach(async function () {
      await token.approve(dividendWithRuleClaimable.address, 100);
      await dividendWithRuleClaimable.createDividend(token.address, accounts[0], 100);
      await waitDelay();
    });

    it('should have claims since a date before the proposal creation', async function () {
      const hasClaims = await dividendWithRuleClaimable.hasClaimsSince(accounts[1], before);
      assert.ok(hasClaims, 'hasClaims');
    });

    it('should have no claims since a date after the proposal creation', async function () {
      const hasClaims = await dividendWithRuleClaimable.hasClaimsSince(accounts[1], before + 3600);
      assert.ok(!hasClaims, 'hasClaims');
    });
  });
});
