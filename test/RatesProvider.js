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
const RatesProvider = artifacts.require('RatesProvider.sol');

contract('RatesProvider', function (accounts) {
  let provider;
  let now = (new Date().getTime() / 1000);

  const aWEICHFSample = 48257890165041;
  const aETHCHFSample = 207220;
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;

  beforeEach(async function () {
    provider = await RatesProvider.new();
  });

  it('should convert rate from ETHCHF', async function () {
    const rateWEICHFCent = await provider.convertRateFromETHCHF(aETHCHFSample, 2);
    assert.equal(rateWEICHFCent.toNumber(), aWEICHFSample, 'rate from ETHCHF');
  });

  it('should convert rate to ETHCHF', async function () {
    const rateETHCHF = await provider.convertRateToETHCHF(aWEICHFSample, 2);
    assert.equal(rateETHCHF.toNumber(), aETHCHFSample, 'rate to ETHCHF');
  });

  it('should convert CHF Cent to 0', async function () {
    const amountWEI = await provider.convertCHFCentToWEI(1000);
    assert.equal(amountWEI.toNumber(), 0, 'WEICHFCents');
  });

  it('should convert WEI to CHFCent to 0', async function () {
    const amountCHFCent = await provider.convertWEIToCHFCent(10**18);
    assert.equal(rateETHCHF.toNumber(), 0, 'no rates');
  });

  it('should have 0 rate WEICHFCent', async function () {
    const rateWEICHFCent = await provider.rateWEIPerCHFCent();
    assert.equal(rateWEICHFCent.toNumber(), 0, 'WEICHFCents');
  });

  it('should have 0 rate ETHCHF', async function () {
    const rateETHCHF = await provider.rateETHCHF(2);
    assert.equal(rateETHCHF.toNumber(), 0, 'no rates');
  });

  it('should let authority define a rate', async function () {
  });

  it('should prevent anyone from defining a rate', async function () {

  });

});
