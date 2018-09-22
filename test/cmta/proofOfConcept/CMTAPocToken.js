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

const CMTAPocToken = artifacts.require('../../contracts/cmta/proofOfConcept/CMTAPocToken.sol');

contract('CMTAPocToken', function (accounts) {
  let token;

  const hash = '0x0000001234567';

  describe('when created with 0 supply', function () {
    beforeEach(async function () {
      token = await CMTAPocToken.new(
        'Test',
        'TST',
        0,
        'Swissquote SA',
        'CHE-666.333.999',
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        100,
        hash);
    });

    it('should have a name', async function () {
      const name = await token.name();
      assert.equal(name, 'Test', 'name');
    });

    it('should have a symbol', async function () {
      const symbol = await token.symbol();
      assert.equal(symbol, 'TST', 'symbol');
    });

    it('should have 0 decimals', async function () {
      const decimals = await token.decimals();
      assert.equal(decimals.toNumber(), 0, 'decimals');
    });

    it('should have 0 supply', async function () {
      const supply = await token.totalSupply();
      assert.equal(supply.toNumber(), 0, 'supply');
    });

    it('should have 0 token in owner balance', async function () {
      const balance = await token.balanceOf(accounts[0]);
      assert.equal(balance.toNumber(), 0, 'balance');
    });

    it('should have an issuer', async function () {
      const issuer = await token.issuer();
      assert.equal(issuer, 'Swissquote SA', 'issuer');
    });

    it('should have a registered number', async function () {
      const registeredNumber = await token.registeredNumber();
      assert.equal(registeredNumber, 'CHE-666.333.999', 'registeredNumber');
    });

    it('should have corporateRegistryURL', async function () {
      const corporateRegistryURL = await token.corporateRegistryURL();
      assert.equal(corporateRegistryURL,
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        'corporateRegistryURL');
    });

    it('should have a valuePerShareCHF', async function () {
      const valuePerShareCHF = await token.valuePerShareCHF();
      assert.equal(valuePerShareCHF.toNumber(), 100, 'valuePerShareCHF');
    });
  });

  describe('when created with 1000000 supply', function () {
    beforeEach(async function () {
      token = await CMTAPocToken.new(
        'Test',
        'TST',
        1000000,
        'Swissquote SA',
        'CHE-666.333.999',
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        100,
        hash);
    });

    it('should have 1000000 supply', async function () {
      const supply = await token.totalSupply();
      assert.equal(supply.toNumber(), 1000000, 'supply');
    });

    it('should have 1000000 token in owner balance', async function () {
      const balance = await token.balanceOf(accounts[0]);
      assert.equal(balance.toNumber(), 1000000, 'balance');
    });
  });
});
