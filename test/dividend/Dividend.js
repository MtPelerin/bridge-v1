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

const ProvableOwnershipTokenMock = artifacts.require('../../contracts/mock/ProvableOwnershipTokenMock.sol');
const Dividend = artifacts.require('../../contracts/Dividend.sol');

contract('Dividend', function (accounts) {
  let token;
  let dividend;
  let payToken1, payToken2;
  let beforeDate;

  const delay = 1;
  async function waitDelay () {
    await new Promise(resolve => setTimeout(resolve, (delay + 1) * 1000));
  }

  beforeEach(async function () {
    beforeDate = Math.floor((new Date()).getTime() / 1000);
    token = await ProvableOwnershipTokenMock.new(accounts[0], 10000, [], []);
    await token.transfer(accounts[1], 200);
    dividend = await Dividend.new(token.address);
  });

  it('should update token', async function () {
    let newToken = await ProvableOwnershipTokenMock.new(accounts[0], 10000, [], []);
    const tx = await dividend.updateToken(newToken.address);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'TokenUpdated');
    assert.equal(tx.logs[0].args.token, newToken.address, 'newToken');
  });
  
  describe('with no dividends', function () {
    it('should return the token address', async function () {
      const tokenAddr = await dividend.token();
      assert.equal(tokenAddr, token.address, 'tokenAddr');
    });

    it('should return 0 for dividendsCount', async function () {
      const dividendsCount = await dividend.dividendsCount();
      assert.equal(dividendsCount, 0, 'dividendsCount');
    });

    it('should create a dividend', async function () {
      payToken1 = await ProvableOwnershipTokenMock.new(accounts[2], 10000, [], []);
      await payToken1.approve(dividend.address, 1000, { from: accounts[2] });
      const tx = await dividend.createDividend(payToken1.address, accounts[2], 1000);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'DividendAdded');
      assert.equal(tx.logs[0].args.id.toNumber(), 0);
      assert.equal(tx.logs[0].args.payToken, payToken1.address);
      assert.equal(tx.logs[0].args.amount.toNumber(), 1000);
    });
  });

  describe('with two dividends', function () {
    beforeEach(async function () {
      // We must ensure that dividends are not created with the same timestamp as the last transaction
      // for accounts[0] and accounts[1]. Otherwise dividendsAvailable will be 0
      await waitDelay();
      payToken1 = await ProvableOwnershipTokenMock.new(accounts[2], 10000, [], []);
      await payToken1.approve(dividend.address, 1000, { from: accounts[2] });
      await dividend.createDividend(payToken1.address, accounts[2], 1000);
      payToken2 = await ProvableOwnershipTokenMock.new(accounts[2], 10000, [], []);
      await payToken2.approve(dividend.address, 2000, { from: accounts[2] });
      await dividend.createDividend(payToken2.address, accounts[2], 2000);
    });

    it('should return 2 for dividendsCount', async function () {
      const dividendsCount = await dividend.dividendsCount();
      assert.equal(dividendsCount, 2, 'dividendsCount');
    });

    it('should return the payment token address for the first dividend', async function () {
      const payTokenAddr = await dividend.dividendPayToken(0);
      assert.equal(payTokenAddr, payToken1.address, 'payToken');
    });

    it('should return the amount for the first dividend', async function () {
      const amount = await dividend.dividendAmount(0);
      assert.equal(amount.toNumber(), 1000, 'amount');
    });

    it('should return the total supply for the first dividend', async function () {
      const totalSupply = await dividend.dividendTotalSupply(0);
      assert.equal(totalSupply.toNumber(), 10000, 'totalSupply');
    });

    it('should return the creation datetime for the first dividend', async function () {
      const createdAt = await dividend.dividendCreatedAt(0);
      assert.ok(createdAt.toNumber() >= beforeDate, 'createdAt');
    });

    it('should have no claim on dividend 0 from account 0', async function () {
      const claimed = await dividend.dividendClaimed(0, accounts[0]);
      assert.equal(claimed.toNumber(), 0, 'claimed');
    });

    it('should have dividend 0 available for account 0', async function () {
      const dividendAvailable = await dividend.dividendAvailable(0, accounts[0]);
      assert.equal(dividendAvailable.toNumber(), 980, 'dividendAvailable');
    });

    it('should have dividend 1 available for account 1', async function () {
      const dividendAvailable = await dividend.dividendAvailable(1, accounts[1]);
      assert.equal(dividendAvailable.toNumber(), 40, 'dividendAvailable');
    });

    it('should let account0 claim dividend 0', async function () {
      const tx = await dividend.claimDividend(0);
      assert.equal(parseInt(tx.receipt.status), 1);
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'DividendClaimed');
      assert.equal(tx.logs[0].args.id, 0, 'id');
      assert.equal(tx.logs[0].args.holder, accounts[0], 'accounts[0]');
      const expectedAmount = Math.round(9800 / 10000 * 1000);
      assert.equal(tx.logs[0].args.amount.toNumber(), expectedAmount, 'amount');
    });

    it('should let account 0 claim dividend 1', async function () {
      const tx = await dividend.claimDividend(1);
      assert.equal(parseInt(tx.receipt.status), 1);
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'DividendClaimed');
      assert.equal(tx.logs[0].args.id, 1, 'id');
      assert.equal(tx.logs[0].args.holder, accounts[0], 'accounts[0]');
      const expectedAmount = Math.round(9800 / 10000 * 2000);
      assert.equal(tx.logs[0].args.amount.toNumber(), expectedAmount, 'amount');
    });

    it('should let account 1 claim dividend 1', async function () {
      const tx = await dividend.claimDividend(1, { from: accounts[1] });
      assert.equal(parseInt(tx.receipt.status), 1);
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'DividendClaimed');
      assert.equal(tx.logs[0].args.id, 1, 'id');
      assert.equal(tx.logs[0].args.holder, accounts[1], 'accounts[1]');
      const expectedAmount = Math.round(200 / 10000 * 2000);
      assert.equal(tx.logs[0].args.amount.toNumber(), expectedAmount, 'amount');
    });

    describe('and claim on dividend 0 done by account 0', function () {
      beforeEach(async function () {
        await dividend.claimDividend(0);
      });

      it('should have already claim all dividend 0 from account 0', async function () {
        const claimed = await dividend.dividendClaimed(0, accounts[0]);
        assert.equal(claimed.toNumber(), 980, 'claimed');
      });

      it('should have no dividend 0 available for account 0', async function () {
        const dividendAvailable = await dividend.dividendAvailable(0, accounts[0]);
        assert.equal(dividendAvailable.toNumber(), 0, 'dividendAvailable');
      });
    });
  });
});
