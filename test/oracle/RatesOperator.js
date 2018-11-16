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
const RatesProvider = artifacts.require('RatesProvider.sol');
const RatesOperator = artifacts.require('RatesOperator.sol');

contract('RatesOperator', function (accounts) {
  let provider, operator;

  const aWEICHFSample = 4825789016504;
  const aETHCHFSample = 207220;

  beforeEach(async function () {
    provider = await RatesProvider.new();
    operator = await RatesOperator.new(provider.address);
    await provider.defineAuthority('OPERATOR', operator.address);
  });

  it('should define operators', async function () {
    const tx = await operator.defineOperators([ 'NOLIMIT', 'LIMITED' ], [ accounts[0], accounts[1] ]);
    assert.equal(parseInt(tx.receipt.status), 1, 'Status');
    assert.equal(tx.logs.length, 3);
    assert.equal(tx.logs[0].event, 'OperatorsCleared', 'event');
    assert.equal(tx.logs[1].event, 'OperatorDefined', 'event');
    assert.equal(tx.logs[2].event, 'OperatorDefined', 'event');
  });

  describe('with operators defined', function () {
    beforeEach(async function () {
      await operator.defineOperators([ 'NOLIMIT', 'LIMITED' ], [ accounts[0], accounts[1] ]);
    });

    it('should let NOLIMIT define rate', async function () {
      const tx = await operator.defineETHCHFRate(aETHCHFSample, 2, { from: accounts[0] });
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
    });

    it('should let LIMIT define rate', async function () {
      const tx = await operator.defineETHCHFRate(aETHCHFSample, 2, { from: accounts[1] });
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
    });

    it('should let NOLIMIT define rate', async function () {
      const tx = await operator.defineRate(aWEICHFSample, { from: accounts[0] });
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
    });

    it('should let LIMIT define rate', async function () {
      const tx = await operator.defineRate(aWEICHFSample, { from: accounts[1] });
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
    });

    it('should define operator threshold', async function () {
      const tx = await operator.defineOperatorThresholds(1, 24 * 3600, 1, 10);
      assert.equal(parseInt(tx.receipt.status), 1, 'Status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'OperatorThresholdsDefined', 'event');
      assert.equal(tx.logs[0].args.operatorId, 1);
      assert.equal(tx.logs[0].args.period.toNumber(), 24 * 3600);
      assert.equal(tx.logs[0].args.frequency.toNumber(), 1);
      assert.equal(tx.logs[0].args.variation.toNumber(), 10);
    });
  });

  describe('with operators and threshold defined', function () {
    beforeEach(async function () {
      await operator.defineOperators([ 'NOLIMIT', 'LIMITED' ], [ accounts[0], accounts[1] ]);
      await operator.defineOperatorThresholds(2, 3600 * 24, 1, 20);
    });

    it('should return lastOperationAt', async function () {
      const lastOperationAt = await operator.lastOperationAt(2);
      assert.equal(lastOperationAt.toNumber(), 0, 'lastOperationAt');
    });

    it('should return frequencyCounter', async function () {
      const frequencyCounter = await operator.frequencyCounter(2);
      assert.equal(frequencyCounter.toNumber(), 0, 'frequencyCounter');
    });

    it('should return frequencyPeriod', async function () {
      const frequencyPeriod = await operator.frequencyPeriod(2);
      assert.equal(frequencyPeriod.toNumber(), 24 * 3600, 'frequencyPeriod');
    });

    it('should return frequencyThreshold', async function () {
      const frequencyThreshold = await operator.frequencyThreshold(2);
      assert.equal(frequencyThreshold.toNumber(), 1, 'frequencyThreshold');
    });

    it('should return variationThreshold', async function () {
      const variationThreshold = await operator.variationThreshold(2);
      assert.equal(variationThreshold.toNumber(), 20, 'variationThreshold');
    });
    
    it('should evalFrequency', async function () {
      const frequency = await operator.evalFrequency(0, 0, 24 * 3600, 1);
      assert.equal(frequency.toNumber(), 24 * 3600, 'frequency');
    });

    it('should evalVariation', async function () {
      const variation = await operator.evalVariation(aWEICHFSample);
      assert.equal(variation.toNumber(), 0, 'variation');
    });

    it('should evalFrequency with an old existing transfer', async function () {
      const frequency = await operator.evalFrequency(24 * 3600, 0, 24 * 3600, 1);
      assert.equal(frequency.toNumber(), 24 * 3600, 'frequency');
    });

    it('should evalFrequency with an existing transfer', async function () {
      const dayMinusHalf = Math.floor((new Date()).getTime() / 1000) - 3600 * 12;
      const frequency = await operator.evalFrequency(24 * 3600, dayMinusHalf, 24 * 3600, 1);
      assert.ok(frequency.toNumber() >  36 * 3595, '> frequency');
      assert.ok(frequency.toNumber() <  36 * 3605, '< frequency');
    });

    it('should evalFrequency with an old existing transfer, 4 per day', async function () {
      const frequency = await operator.evalFrequency(24 * 3600, 0, 24 * 3600, 4);
      assert.equal(frequency.toNumber(), 24 * 3600, 'frequency');
    });

    it('should evalFrequency with an existing transfer, 4 per day', async function () {
      const dayMinus4Hours = Math.floor((new Date()).getTime() / 1000) - 3600 * 4;
      const frequency = await operator.evalFrequency(24 * 3600, dayMinus4Hours, 24 * 3600, 4);
      assert.ok(frequency.toNumber() >  24 * 3600 * 2 - 4 * 3600 * 4 - 5, '> frequency');
      assert.ok(frequency.toNumber() <  24 * 3600 * 2 - 4 * 3600 * 4 + 5, '< frequency');
    });

    it('should evalVariation', async function () {
      const variation = await operator.evalVariation(aWEICHFSample);
      assert.equal(variation.toNumber(), 0, 'variation');
    });

    describe('with a rate already defined', function () {
      let beforeDate, afterDate;
      beforeEach(async function () {
        beforeDate = new Date().getTime() / 1000 - 1;
        const tx = await operator.defineRate(aWEICHFSample, { from: accounts[1] });
        assert.equal(parseInt(tx.receipt.status), 1, 'Status');
        afterDate = new Date().getTime() / 1000 + 1;
      });

      it('should return lastOperationAt', async function () {
        const lastOperationAt = await operator.lastOperationAt(2);
        assert.ok(lastOperationAt.toNumber() > beforeDate, 'lastOperationAt before');
        assert.ok(lastOperationAt.toNumber() < afterDate, 'lastOperationAt after');
      });

      it('should return frequencyCounter', async function () {
        const frequencyCounter = await operator.frequencyCounter(2);
        assert.equal(frequencyCounter.toNumber(), 24 * 3600, 'frequencyCounter');
      });

      it('should not let LIMIT operator define twice within a day', async function () {
        await assertRevert(operator.defineRate(aWEICHFSample, { from: accounts[1] }));
      });
    });
  });
});
