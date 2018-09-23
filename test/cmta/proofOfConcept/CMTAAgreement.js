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

const assertRevert = require('../../helpers/assertRevert');
const CMTAAgreement = artifacts.require('../../contracts/cmta/mock/CMTAAgreement.sol');

contract('CMTAAgreement', function (accounts) {
  const hash = '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a';
  let agreement;

  beforeEach(async function () {
    agreement = await CMTAAgreement.new(hash);
  });

  it('should retrieve the hash', async function () {
    const agreementHash = await agreement.agreementHash();
    assert.equal(agreementHash, hash, 'hash');
  });

  it('should return if the address has accepted the agreement', async function () {
    const accepted = await agreement.isAgreementAccepted(accounts[1]);
    assert.ok(!accepted, 'not accepted');
  });

  it('should update the agreement', async function () {
    const tx = await agreement.updateAgreement('0x00000001');
    assert.equal(tx.receipt.status, '0x1', 'status');
  });

  it('should not let non owner update the agreement', async function () {
    await assertRevert(agreement.updateAgreement('0x00000001', { from: accounts[1] }));
  });

  it('should accept the agreement', async function () {
    const tx = await agreement.acceptAgreement(hash);
    assert.equal(tx.receipt.status, '0x1', 'status');
  });

  describe('with account 1 accepted', function () {
    beforeEach(async function () {
      await agreement.acceptAgreement(hash, { from: accounts[1] });
    });
    
    it('should have owner accepted', async function () {
      const accepted = await agreement.isAgreementAccepted(accounts[0]);
      assert.ok(accepted, 'accepted');
    });

    it('should have account 1 accepted', async function () {
      const accepted = await agreement.isAgreementAccepted(accounts[1]);
      assert.ok(accepted, 'accepted');
    });

    it('should have account 2 not accepted', async function () {
      const accepted = await agreement.isAgreementAccepted(accounts[2]);
      assert.ok(!accepted, 'accepted');
    });
  });
});
