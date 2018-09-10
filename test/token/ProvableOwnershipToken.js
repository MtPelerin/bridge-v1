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

const ProvableOwnershipTokenMock = artifacts.require('mocks/ProvableOwnershipTokenMock.sol');

contract('ProvableOwnershipToken', function (accounts) {
  let token;
  let beforeDate;
  let afterDate;

  beforeEach(async function () {
    beforeDate = Math.floor((new Date()).getTime() / 1000);
    token = await ProvableOwnershipTokenMock.new(accounts[0], 100,
      [ accounts[1], accounts[1], accounts[2] ],
      [ 11, 31, 22 ]);
    afterDate = Math.ceil((new Date()).getTime() / 1000);
  });

  it('should have proofs length for account1', async function () {
    const length = await token.proofLength(accounts[1]);
    assert.equal(length.toNumber(), 2, 'length');
  });

  it('should have last transaction for account1', async function () {
    const lastTransactionAt = await token.lastTransactionAt(accounts[1]);
    assert.equal(lastTransactionAt.toNumber(), 0, 'lastTransactionAt');
  });

  it('should check valid proofId for account1', async function () {
    const begin = await token.checkProof(accounts[1], 0, 0);
    assert.equal(begin.toNumber(), 11, 'proof amount at 0');

    const amount = await token.checkProof(accounts[1], 0, beforeDate);
    assert.equal(amount.toNumber(), 11, 'amount');

    const after = await token.checkProof(accounts[1], 0, afterDate);
    assert.equal(after.toNumber(), 0, 'proof amount after proof');
  });

  it('should check invalid proofId for an existing address', async function () {
    const amount = await token.checkProof(accounts[1], 100, beforeDate);
    assert.equal(amount.toNumber(), 0, 'amount');
  });

  it('should check invalid proofId for an non existing address', async function () {
    const amount = await token.checkProof(accounts[0], 0, beforeDate);
    assert.equal(amount.toNumber(), 0, 'amount');
  });

  it('should return proofId details', async function () {
    const amount = await token.proofAmount(accounts[1], 0);
    assert.equal(amount.toNumber(), 11, 'amount');
    const dateFrom = (await token.proofDateFrom(accounts[1], 0)).toNumber();
    assert.equal(dateFrom, 0, 'dateFrom');
    const dateTo = (await token.proofDateTo(accounts[1], 0)).toNumber();
    assert.ok(dateTo >= beforeDate && dateTo <= afterDate, 'dateTo');
  });

  it('should create a valid proof', async function () {
    const beforeDate = Math.floor((new Date()).getTime() / 1000);
    const lengthBefore = await token.proofLength(accounts[0]);
    assert.equal(lengthBefore.toNumber(), 0, 'lengthBefore');
    const receipt = await token.createProof(accounts[0]);
    const afterDate = Math.ceil((new Date()).getTime() / 1000);
 
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'ProofOfOwnership');
    assert.equal(receipt.logs[0].args.holder, accounts[0], 'holder');
    assert.equal(receipt.logs[0].args.proofId.toNumber(), 0, 'proofId');
  
    const length = await token.proofLength(accounts[0]);
    assert.equal(length.toNumber(), 1, 'length');
    const amount = await token.proofAmount(accounts[0], 0);
    assert.equal(amount.toNumber(), 100, 'amount');
    const dateFrom = (await token.proofDateFrom(accounts[0], 0)).toNumber();
    assert.equal(dateFrom, 0, 'dateFrom');
    const dateTo = (await token.proofDateTo(accounts[0], 0)).toNumber();
    assert.ok(dateTo >= beforeDate && dateTo <= afterDate, 'dateTo');
  });

  it('should update lastTransactionAt during transfer', async function () {
    const beforeDate = Math.floor((new Date()).getTime() / 1000);
    const receipt = await token.transfer(accounts[1], 10);
    assert.equal((await token.balanceOf(accounts[0])).toNumber(), 90, 'balance accounts[1]');
    assert.equal((await token.balanceOf(accounts[1])).toNumber(), 10, 'balance accounts[1]');
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'Transfer');

    const lastTransactionAt0 = await token.lastTransactionAt(accounts[0]);
    assert.ok(lastTransactionAt0.toNumber() >= beforeDate, 'lastTransactionAt0');
    const lastTransactionAt1 = await token.lastTransactionAt(accounts[1]);
    assert.ok(lastTransactionAt1.toNumber() >= beforeDate, 'lastTransactionAt1');
  });

  it('should update lastTransactionAt during transferFrom', async function () {
    const beforeDate = Math.floor((new Date()).getTime() / 1000);
    await token.approve(accounts[2], 100);
    const receipt = await token.transferFrom(accounts[0], accounts[1], 10, { from: accounts[2] });
    assert.equal((await token.balanceOf(accounts[0])).toNumber(), 90, 'balance accounts[1]');
    assert.equal((await token.balanceOf(accounts[1])).toNumber(), 10, 'balance accounts[1]');
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'Transfer');

    const lastTransactionAt0 = await token.lastTransactionAt(accounts[0]);
    assert.ok(lastTransactionAt0.toNumber() >= beforeDate, 'lastTransactionAt0');
    const lastTransactionAt1 = await token.lastTransactionAt(accounts[1]);
    assert.ok(lastTransactionAt1.toNumber() >= beforeDate, 'lastTransactionAt1');
  });

  it('should transfer with a proof of ownership', async function () {
    const beforeDate = Math.floor((new Date()).getTime() / 1000);
    const receipt = await token.transferWithProofs(accounts[1], 10, true, false);
    assert.equal((await token.balanceOf(accounts[0])).toNumber(), 90, 'balance accounts[1]');
    assert.equal((await token.balanceOf(accounts[1])).toNumber(), 10, 'balance accounts[1]');
    assert.equal(receipt.logs.length, 2);
    assert.equal(receipt.logs[0].event, 'Transfer');
    assert.equal(receipt.logs[1].event, 'ProofOfOwnership');
    assert.equal(receipt.logs[1].args.holder, accounts[0], 'holder');
    assert.equal(receipt.logs[1].args.proofId.toNumber(), 0, 'proofId');

    const lastTransactionAt0 = await token.lastTransactionAt(accounts[0]);
    assert.ok(lastTransactionAt0.toNumber() >= beforeDate, 'lastTransactionAt0');
    const lastTransactionAt1 = await token.lastTransactionAt(accounts[1]);
    assert.ok(lastTransactionAt1.toNumber() >= beforeDate, 'lastTransactionAt1');
  });

  it('should transferFrom with a proof of ownership', async function () {
    const beforeDate = Math.floor((new Date()).getTime() / 1000);
    await token.approve(accounts[2], 100);
    await token.transfer(accounts[1], 5);
    const receipt = await token.transferFromWithProofs(
      accounts[0], accounts[1],
      10, false, true, { from: accounts[2],
      });
    assert.equal((await token.balanceOf(accounts[0])).toNumber(), 85, 'balance accounts[1]');
    assert.equal((await token.balanceOf(accounts[1])).toNumber(), 15, 'balance accounts[1]');
    assert.equal(receipt.logs.length, 2);
    assert.equal(receipt.logs[0].event, 'Transfer');
    assert.equal(receipt.logs[1].event, 'ProofOfOwnership');
    assert.equal(receipt.logs[1].args.holder, accounts[1], 'holder');
    assert.equal(receipt.logs[1].args.proofId.toNumber(), 2, 'proofId');

    const lastTransactionAt0 = await token.lastTransactionAt(accounts[0]);
    assert.ok(lastTransactionAt0.toNumber() >= beforeDate, 'lastTransactionAt0');
    const lastTransactionAt1 = await token.lastTransactionAt(accounts[1]);
    assert.ok(lastTransactionAt1.toNumber() >= beforeDate, 'lastTransactionAt1');
  });
});
