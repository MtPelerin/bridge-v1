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
const StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');
const UserRegistry = artifacts.require('UserRegistry.sol');
const Tokensale = artifacts.require('tokensale/Tokensale.sol');
const RatesProvider = artifacts.require('RatesProvider.sol');

contract('Tokensale', function (accounts) {
  let sale, token, userRegistry, ratesProvider;
  let now = (new Date().getTime() / 1000);

  const vaultERC20 = accounts[1];
  const vaultETH = accounts[0];

  const sharePurchaseAgreementHash = web3.sha3('SharePurchaseAgreement');
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;

  beforeEach(async function () {
    token = await StandardTokenMock.new(accounts[1], 10000);
    userRegistry = await UserRegistry.new([], 0);
    ratesProvider = await RatesProvider.new();
    sale = await Tokensale.new(token.address, userRegistry.address, ratesProvider.address, vaultERC20, vaultETH);
    await token.approve(sale.address, 10000, { from: accounts[1] });
  });

  it('should have a token', async function () {
    const saleTokenAddress = await sale.token();
    assert.equal(saleTokenAddress, token.address, 'token');
  });

  it('should have a vaultERC20', async function () {
    const saleVaultERC20 = await sale.vaultERC20();
    assert.equal(saleVaultERC20, vaultERC20, 'vaulrERC20');
  });


  it('should have a vaultETH', async function () {
    const saleVaultETH = await sale.vaultETH();
    assert.equal(saleVaultETH, vaultETH, 'vaulrETH');
  });

  it('should have a user registry', async function () {
    const saleUserRegistryAddress = await sale.userRegistry();
    assert.equal(saleUserRegistryAddress, userRegistry.address, 'userRegistry');
  });

  it('should have a share purchase agreement hash non defini', async function () {
    const saleSharePurchaseAgreement = await sale.sharePurchaseAgreementHash();
    assert.equal(saleSharePurchaseAgreement, 0,  'sharePurchaseAgreementHash');
  });

  describe('before the sale has start', async function () {

  });

  describe('during the sale', async function () {

  });

  describe('after the sale', async function () {

  });
});
