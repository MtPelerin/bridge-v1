'User strict';

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
const KnowYourCustomer = artifacts.require('../kycs/demo/KnowYourCustomer.sol');

contract('KnowYourCustomer', function (accounts) {
  let kyc;
  const tomorrow = Math.floor((new Date().getTime() / 1000) + 24 * 3600);

  beforeEach(async function () {
    kyc = await KnowYourCustomer.new();
  });

  it('should have KYC valid for owner', async function () {
    const isValid = await kyc.isKYCValid(accounts[0]);
    assert.ok(isValid, 'owner\'s KYC is valid');
  });

  it('should not have KYC valid for non owner', async function () {
    const isValid = await kyc.isKYCValid(accounts[1]);
    assert.ok(!isValid, 'non owner KYC is not valid');
  });

  it('should have owner KYC valid until 0', async function () {
    const validUntil = await kyc.validUntil(accounts[0]);
    assert.equal(validUntil.toNumber(), 0, 'valid until owner');
  });

  it('should have non owner KYC valid until 0', async function () {
    const validUntil = await kyc.validUntil(accounts[1]);
    assert.equal(validUntil.toNumber(), 0, 'valid until');
  });

  it('should allow to valid KYC', async function () {
    const tx = await kyc.validateKYCUntil(accounts[1], tomorrow);
    assert.equal(tx.receipt.status, '0x1', 'status');
    const isValid = await kyc.isKYCValid(accounts[1]);
    assert.ok(isValid, 'is valid');
    const validUntil = await kyc.validUntil(accounts[1]);
    assert.equal(validUntil.toNumber(), tomorrow, 'valid until');
  });

  it('should not allow to validate KYC from non owner ', async function () {
    await assertRevert(kyc.validateKYCUntil(accounts[1], tomorrow, { from: accounts[1] }));
  });

  it('should allow to valid many KYC', async function () {
    const tx = await kyc.validateManyKYCUntil(accounts, tomorrow);
    assert.equal(tx.receipt.status, '0x1', 'status');
    const isValid = await kyc.isKYCValid(accounts[8]);
    assert.ok(isValid, 'is valid');
    const validUntil = await kyc.validUntil(accounts[8]);
    assert.equal(validUntil.toNumber(), tomorrow, 'valid until');
  });

  it('should not allow to validate many KYC from non owner ', async function () {
    await assertRevert(kyc.validateManyKYCUntil(accounts, tomorrow, { from: accounts[1] }));
  });
});
