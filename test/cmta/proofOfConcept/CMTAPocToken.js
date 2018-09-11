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

const assertRevert = require('../../helpers/assertRevert');
const CMTAPocToken = artifacts.require('../../contracts/cmta/proofOfConcept/CMTAPocToken.sol');

contract('CMTAPocToken', function (accounts) {
  let token;

  beforeEach(async function () {
    token = await CMTAPocToken.new('Name', 'SMB');
  });

  it('should have a name', async function () {
    const name = await token.name();
    assert.equal(name, 'Name', 'name');
  });

  it('should have a symbol', async function () {
    const symbol = await token.symbol();
    assert.equal(symbol, 'SMB', 'symbol');
  });

  it('should have 0 decimals', async function () {
    const decimals = await token.decimals();
    assert.equal(decimals.toNumber(), 0, 'decimals');
  });
});
