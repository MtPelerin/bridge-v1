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

const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTAShareholderAgreement =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareholderAgreement.sol');

contract('BoardSig', function (accounts) {
  const hash = '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a';
  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let token, shareholderAgreement;

  it('should not create the Shareholder Agreement without hash', async function () {
    await assertRevert(CMTAShareholderAgreement.new(0, nextYear));
  });

  it('should not create the Shareholder Agreement without a registerUntil valid', async function () {
    await assertRevert(CMTAShareholderAgreement.new(hash, 0));
  });

  it('should create the Shareholder agreement', async function () {
    shareholderAgreement = await CMTAShareholderAgreement.new(hash, nextYear);
    assert.notEqual(
      shareholderAgreement.address,
      '0x0000000000000000000000000000000000000000',
      'shareholderAgreement address is not null'
    );
  });

  describe('with a shareholder agreement and a token', function () {
    beforeEach(async function () {
      shareholderAgreement = await CMTAShareholderAgreement.new(
        '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a',
        nextYear
      );
      token = await CMTAPocToken.new(
        'Test',
        'TST',
        'Swissquote SA',
        'CHE-666.333.999',
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        100);
    });

    it('should not configure the token without a token', async function () {
      await assertRevert(shareholderAgreement.configureToken('0x0000000000000000000000000000000000000000'));
    });

    it('should not configure the token without ownership of it', async function () {
      await token.issue(100000);
      await token.transfer(shareholderAgreement.address, 100000);
      await assertRevert(shareholderAgreement.configureToken(token.address));
    });

    it('should not configure the token without any supply', async function () {
      await token.transferOwnership(shareholderAgreement.address);
      await assertRevert(shareholderAgreement.configureToken(token.address));
    });

    it('should not configure the token without owning all tokens', async function () {
      await token.issue(100000);
      await token.transfer(shareholderAgreement.address, 99999);
      await token.transferOwnership(shareholderAgreement.address);
      await assertRevert(shareholderAgreement.configureToken(token.address));
    });

    it('should not let non owner configure the token', async function () {
      await token.issue(100000);
      await token.transfer(shareholderAgreement.address, 100000);
      await token.transferOwnership(shareholderAgreement.address);
      await assertRevert(shareholderAgreement.configureToken(token.address,
        { from: accounts[1] }));
    });

    it('should configure the token', async function () {
      await token.issue(100000);
      await token.transfer(shareholderAgreement.address, 100000);
      await token.transferOwnership(shareholderAgreement.address);
      const tx = await shareholderAgreement.configureToken(token.address);
      assert.equal(tx.receipt.status, '0x01', 'status');
    });

    describe('and the token configured', function () {
      beforeEach(async function () {
        await token.issue(100000);
        await token.transfer(shareholderAgreement.address, 100000);
        await token.transferOwnership(shareholderAgreement.address);
        await shareholderAgreement.configureToken(token.address);
      });

      it('should not allow token to be configured twice', async function () {
        await assertRevert(shareholderAgreement.configureToken(token.address));
      });

      it('should allow allocates shares', async function () {
        const tx = await shareholderAgreement.allocateShares(accounts[1], 80000);
        assert.equal(tx.receipt.status, '0x01', 'status');
      });

      it('should not allow to allocates more shares than available', async function () {
        await assertRevert(shareholderAgreement.allocateShares(accounts[1], 100001));
      });

      it('should not allow non owner to allocates shares', async function () {
        await assertRevert(
          shareholderAgreement.allocateShares(
            accounts[1], 80000, { from: accounts[1] }));
      });

      it('should not allow finish allocations (tokens not allocated)', async function () {
        await shareholderAgreement.allocateShares(accounts[1], 80000);
        await assertRevert(shareholderAgreement.finishAllocations());
      });

      describe('and all allocations done', async function () {
        beforeEach(async function () {
          await shareholderAgreement.allocateShares(accounts[1], 80000);
          await shareholderAgreement.allocateShares(accounts[2], 20000);
        });

        it('should allow update allocated shares', async function () {
          const tx = await shareholderAgreement.allocateShares(accounts[1], 12000);
          assert.equal(tx.receipt.status, '0x01', 'status');
        });

        it('should allow finish allocations', async function () {
          const tx = await shareholderAgreement.finishAllocations();
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, 'OwnershipTransferred');
          assert.equal(tx.logs[0].args.previousOwner, shareholderAgreement.address);
          assert.equal(tx.logs[0].args.newOwner, accounts[0]);
          assert.equal(tx.logs[1].event, 'AllocationFinished');
        });

        it('should not allow non owner to finish allocations', async function () {
          await assertRevert(shareholderAgreement.finishAllocations({ from: accounts[1] }));
        });

        describe('with allocations finished', async function () {
          beforeEach(async function () {
            await shareholderAgreement.finishAllocations();
          });

          it('should not finish allocations twice', async function () {
            await assertRevert(shareholderAgreement.finishAllocations());
          });

          it('should allow holder to claim shares', async function () {
            const tx = await shareholderAgreement.claimShares(hash, { from: accounts[1] });
            assert.equal(tx.receipt.status, '0x01', 'status');
          });

          it('should not allow holder to claim twice shares', async function () {
            await shareholderAgreement.claimShares(hash, { from: accounts[1] });
            await assertRevert(
              shareholderAgreement.claimShares(hash, { from: accounts[1] }));
          });

          it('should prevent non holder to claim shares', async function () {
            await assertRevert(shareholderAgreement.claimShares(hash));
          });
        });
      });
    });
  });
});
