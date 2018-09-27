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
var AuthorityMock = artifacts.require('../contracts/mock/AuthorityMock.sol');

contract('Authority', function (accounts) {
  let authority;
  const authorityAddress = accounts[2];

  beforeEach(async function () {
    authority = await AuthorityMock.new();
  });

  it('should have no authority', async function () {
    const authorityCheck = await authority.authorityAddress('REGULATOR');
    assert.equal(authorityCheck, '0x0000000000000000000000000000000000000000');
  });

  it('should allow owner to set a new authority', async function () {
    const tx = await authority.defineAuthority('REGULATOR', authorityAddress);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'AuthorityDefined');
    assert.equal(tx.logs[0].args.name, 'REGULATOR');
    assert.equal(tx.logs[0].args._address, authorityAddress);
  });

  describe('with authorities defined', function () {
    beforeEach(async function () {
      await authority.defineAuthority('REGULATOR', authorityAddress);
      await authority.defineAuthority('LEGAL1', accounts[1]);
    });

    it('should allow authority through onlyAuthority modifier', async function () {
      await authority.testOnlyAuthority('REGULATOR', { from: accounts[2] });
    });

    it('should not allow another authority through onlyAuthority modifier', async function () {
      await assertRevert(authority.testOnlyAuthority('REGULATOR', { from: accounts[1] }));
    });
     
    it('should not allow non authority through onlyAuthority modifier', async function () {
      await assertRevert(authority.testOnlyAuthority('REGULATOR'));
    });
  });
});
