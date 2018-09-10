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
const BasicToken = artifacts.require('../contracts/BasicToken.sol');
const Rates = artifacts.require('../contracts/Rates.sol');

contract('Rates', function (accounts) {
  let basicToken;
  let rates;
  let tokenAddresses = [
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000002',
    '0x0000000000000000000000000000000000000003',
  ];
  
  describe('with no rates', function () {
    beforeEach(async function () {
      basicToken = await BasicToken.new();
      rates = await Rates.new(basicToken.address, [], [], []);
    });

    it('should have a referenceToken', async function () {
      const referenceToken = await rates.referenceToken();
      assert.equal(referenceToken, basicToken.address, 'referenceToken');
    });

    it('should have a default ratePrecision', async function () {
      const ratePrecision = await rates.ratePrecision();
      assert.equal(ratePrecision.toNumber(), 2, 'ratePrecision');
    });

    it('should have no tokens when empty', async function () {
      const tokens = await rates.tokens();
      assert.deepEqual(tokens, [], 'tokens');
    });

    it('should let owner update the referenceToken', async function () {
      const newToken = await BasicToken.new();
      await rates.updateReferenceToken(newToken.address);
      const referenceToken = await rates.referenceToken();
      assert.equal(referenceToken, newToken.address, 'referenceToken');
    });

    it('should prevent non-owner to update the referenceToken', async function () {
      await assertRevert(rates.updateReferenceToken(0, { from: accounts[1] }));
    });

    it('should let owner update ratePrecision', async function () {
      await rates.updateRatePrecision(5);
      const ratePrecision = await rates.ratePrecision();
      assert.equal(ratePrecision.toNumber(), 5, 'ratePrecision');
    });

    it('should prevent non-owner to update the ratePrecision', async function () {
      await assertRevert(rates.updateRatePrecision(0, { from: accounts[1] }));
    });
  });

  describe('with some rates', function () {
    const start = new Date();

    beforeEach(async function () {
      basicToken = await BasicToken.new();
      rates = await Rates.new(basicToken.address, tokenAddresses,
        [ 123, 99, 111 ], [ 81, 100, 90 ]);
    });

    it('should have tokens', async function () {
      const tokens = await rates.tokens();
      assert.deepEqual(tokens, tokenAddresses, 'tokens');
    });

    it('should have a rate for each token', async function () {
      const rate0 = await rates.rate(tokenAddresses[0]);
      assert.equal(rate0, 123, 'rate0');
      const rate1 = await rates.rate(tokenAddresses[1]);
      assert.equal(rate1, 99, 'rate1');
    });

    it('should have a inverted rate for each token', async function () {
      const rate0 = await rates.invertedRate(tokenAddresses[0]);
      assert.equal(rate0, 81, 'invertedRate0');
      const rate1 = await rates.invertedRate(tokenAddresses[1]);
      assert.equal(rate1, 100, 'invertedRate1');
    });

    it('should have a last update date for each token', async function () {
      const now = new Date();
      const updatedAt0 = 1000 * (await rates.updatedAt(tokenAddresses[0])).toNumber();
      assert.ok(updatedAt0 >= start && updatedAt0 <= now, 'updatedAt0');
      const updatedAt1 = 1000 * (await rates.updatedAt(tokenAddresses[1])).toNumber();
      assert.ok(updatedAt1 >= start && updatedAt1 <= now, 'updatedAt1');
    });

    it('should let owner update a rate', async function () {
      await rates.updateRate(0, 145, 68);
      const rate0 = await rates.rate(tokenAddresses[0]);
      assert.equal(rate0.toNumber(), 145, 'rate0');
      const invertedRate0 = await rates.invertedRate(tokenAddresses[0]);
      assert.equal(invertedRate0.toNumber(), 68, 'invertedRate0');
    });

    it('should let owner update many rates', async function () {
      await rates.updateManyRates([0, 2], [ 75, 119 ], [ 125, 81 ]);
      const rate0 = await rates.rate(tokenAddresses[0]);
      assert.equal(rate0.toNumber(), 75, 'rate0');
      const invertedRate0 = await rates.invertedRate(tokenAddresses[0]);
      assert.equal(invertedRate0.toNumber(), 125, 'invertedRate0');
      const rate1 = await rates.rate(tokenAddresses[2]);
      assert.equal(rate1.toNumber(), 119, 'rate1');
      const invertedRate1 = await rates.invertedRate(tokenAddresses[2]);
      assert.equal(invertedRate1.toNumber(), 81, 'invertedRate1');
    });

    it('should let owner add a token', async function () {
      const newTokenAddr = '0x0000000000000000000000000000000000000004';
      await rates.addToken(newTokenAddr, 112, 88);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 4, 'tokens.length');
      assert.equal(tokens[3], newTokenAddr, 'newTokenAddr');
      const rate = await rates.rate(newTokenAddr);
      assert.equal(rate.toNumber(), 112, 'rate');
      const invertedRate = await rates.invertedRate(newTokenAddr);
      assert.equal(invertedRate.toNumber(), 88, 'invertedRate');
    });

    it('should let owner add many tokens', async function () {
      const newTokensAddr = [
        '0x0000000000000000000000000000000000000004',
        '0x0000000000000000000000000000000000000005',
      ];
      const rateData = [ 101, 102 ];
      const invertedRates = [ 99, 98 ];
      await rates.addManyTokens(newTokensAddr, rateData, invertedRates);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 5, 'tokens.length');
      for (let i = 0; i < newTokensAddr.length; i++) {
        assert.equal(tokens[3 + i], newTokensAddr[i], 'newTokenAddr' + i);
        const rate = await rates.rate(newTokensAddr[i]);
        assert.equal(rate, rateData[i], 'rate' + i);
        const invertedRate = await rates.invertedRate(newTokensAddr[i]);
        assert.equal(invertedRate, invertedRates[i], 'invertedRate' + i);
      }
    });

    it('should let owner remove a token', async function () {
      await rates.removeToken(0);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 2, 'length');
      assert.equal(tokens.indexOf(tokenAddresses[0]), -1, 'tokenAddress');
      const rate = await rates.rate(tokenAddresses[0]);
      assert.equal(rate, 0, 'rate');
      const invertedRate = await rates.invertedRate(tokenAddresses[0]);
      assert.equal(invertedRate, 0, 'invertedRate');
    });

    it('should let owner remove the last token', async function () {
      await rates.removeToken(0);
      await rates.removeToken(0);
      await rates.removeToken(0);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 0, 'tokens.length');
    });

    it('should let owner remove many tokens', async function () {
      await rates.removeManyTokens([0, 1]);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 1, 'tokens.length');
      assert.equal(tokens[0], tokenAddresses[2]);
    });

    it('should let owner remove all the tokens', async function () {
      await rates.removeManyTokens([ 0, 0, 0 ]);
      const tokens = await rates.tokens();
      assert.equal(tokens.length, 0, 'tokens.length');
    });

    it('should prevent non-owner to update a token rate', async function () {
      await assertRevert(rates.updateRate(tokenAddresses[0], 1, 1, { from: accounts[1] }));
    });

    it('should prevent non-owner to update many tokens rate', async function () {
      await assertRevert(rates.updateManyRates([tokenAddresses[0]], [1], [1], { from: accounts[1] }));
    });

    it('should prevent non-owner to add a token', async function () {
      await assertRevert(rates.addToken(tokenAddresses[0], 1, 1, { from: accounts[1] }));
    });

    it('should prevent non-owner to add many tokens', async function () {
      await assertRevert(rates.addManyTokens([tokenAddresses[0]], [1], [1], { from: accounts[1] }));
    });

    it('should prevent non-owner to remove a token', async function () {
      await assertRevert(rates.removeToken(0, { from: accounts[1] }));
    });

    it('should prevent non-owner to remove many tokens', async function () {
      await assertRevert(rates.removeManyTokens([0], { from: accounts[1] }));
    });
  });
});
