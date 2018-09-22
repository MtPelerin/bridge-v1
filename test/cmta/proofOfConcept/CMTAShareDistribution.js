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
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

contract('ShareDistribution', function (accounts) {
  const hash = '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a';
  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let token, shareDistribution;

  it('should not create the Shareholder Agreement without hash', async function () {
    await assertRevert(CMTAShareDistribution.new(0, nextYear));
  });

  it('should create the Shareholder Distribution', async function () {
    shareDistribution = await CMTAShareDistribution.new(hash, nextYear);
    assert.notEqual(
      shareDistribution.address,
      '0x0000000000000000000000000000000000000000',
      'shareDistribution address is not null'
    );
  });

  describe('with a share distribution and a token', function () {
    beforeEach(async function () {
      shareDistribution = await CMTAShareDistribution.new(
        hash,
        nextYear
      );
      token = await CMTAPocToken.new(
        'Test',
        'TST',
        0,
        'Swissquote SA',
        'CHE-666.333.999',
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        100,
        hash);
      await token.acceptAgreement(hash, { from: accounts[1] });
    });

    it('should not configure the token without a token', async function () {
      await assertRevert(
        shareDistribution.configureToken(
          '0x0000000000000000000000000000000000000000',
          hash
        ));
    });

    it('should not allow non owner to configure the token', async function () {
      await assertRevert(
        shareDistribution.configureToken(
          token.address, hash, { from: accounts[1] }));
    });

    it('should configure the token', async function () {
      const tx = await shareDistribution.configureToken(token.address, hash);
      assert.equal(tx.receipt.status, '0x01', 'status');
    });

    describe('and the token configured', function () {
      beforeEach(async function () {
        await shareDistribution.configureToken(token.address, hash);
      });

      it('should not allow token to be configured twice', async function () {
        await assertRevert(shareDistribution.configureToken(token.address, hash));
      });

      it('should allow allocates shares', async function () {
        const tx = await shareDistribution.allocateShares(accounts[1], 80000);
        assert.equal(tx.receipt.status, '0x01', 'status');
      });

      it('should not allow non owner to allocates shares', async function () {
        await assertRevert(
          shareDistribution.allocateShares(
            accounts[1], 80000, { from: accounts[1] }));
      });

      it('should not allow finish allocations (no tokens to distribute)', async function () {
        await shareDistribution.allocateShares(accounts[1], 80000);
        await assertRevert(shareDistribution.finishAllocations());
      });

      describe('and all allocations done and tokens available', async function () {
        beforeEach(async function () {
          await shareDistribution.allocateShares(accounts[1], 80000);
          await shareDistribution.allocateShares(accounts[2], 20000);
        });

        it('should allow update allocated shares', async function () {
          const tx = await shareDistribution.allocateShares(accounts[1], 12000);
          assert.equal(tx.receipt.status, '0x01', 'status');
        });

        it('should not allow to finish allocations (missing tokens)', async function () {
          await token.validateKYCUntil(shareDistribution.address, nextYear);
          await assertRevert(shareDistribution.finishAllocations());
        });

        it('should not allow to finish allocations (share distribution not KYCed', async function () {
          await token.issue(100000);
          await token.transfer(shareDistribution.address, 100000);
          await assertRevert(shareDistribution.finishAllocations());
        });

        it('should allow finish allocations', async function () {
          await token.issue(100000);
          await token.transfer(shareDistribution.address, 100000);
          await token.validateKYCUntil(shareDistribution.address, nextYear);
          const tx = await shareDistribution.finishAllocations();
          assert.equal(tx.receipt.status, '0x01', 'status');
          assert.equal(tx.logs.length, 1);
          assert.equal(tx.logs[0].event, 'AllocationFinished');
        });

        it('should not allow non owner to finish allocations', async function () {
          await assertRevert(shareDistribution.finishAllocations({ from: accounts[1] }));
        });

        describe('with allocations finished', async function () {
          beforeEach(async function () {
            await token.issue(100000);
            await token.transfer(shareDistribution.address, 100000);
            await token.validateKYCUntil(shareDistribution.address, nextYear);
            await shareDistribution.finishAllocations();
          });

          it('should not finish allocations twice', async function () {
            await assertRevert(shareDistribution.finishAllocations());
          });

          it('should allow holder to claim shares', async function () {
            const tx = await shareDistribution.claimShares(hash, { from: accounts[1] });
            assert.equal(tx.receipt.status, '0x01', 'status');
          });

          it('should not allow holder to claim twice shares', async function () {
            await shareDistribution.claimShares(hash, { from: accounts[1] });
            await assertRevert(
              shareDistribution.claimShares(hash, { from: accounts[1] }));
          });

          it('should prevent non holder to claim shares', async function () {
            await assertRevert(shareDistribution.claimShares(hash));
          });
        });
      });
    });
  });

  describe('with a no distributionEnd share distribution allocated and a token', function () {
    beforeEach(async function () {
      shareDistribution = await CMTAShareDistribution.new(
        hash,
        0
      );
      token = await CMTAPocToken.new(
        'Test',
        'TST',
        100000,
        'Swissquote SA',
        'CHE-666.333.999',
        'https://ge.ch/hrcintapp/externalCompanyReport.action?companyOfsUid=CHE-666.333.999&lang=EN',
        100,
        hash);
      await shareDistribution.configureToken(token.address, hash);

      await token.acceptAgreement(hash, { from: accounts[1] });
      await token.transfer(shareDistribution.address, 100000);
      await token.validateKYCUntil(shareDistribution.address, nextYear);
      await shareDistribution.allocateShares(accounts[1], 80000);
      await shareDistribution.allocateShares(accounts[2], 20000);
      await shareDistribution.finishAllocations();
    });

    it('should not allow to reclaim too many shares', async function () {
      await assertRevert(shareDistribution.reclaimShares(100001));
    });

    it('should not allow to reclaim shares by non owner', async function () {
      await assertRevert(shareDistribution.reclaimShares(100000, { from: accounts[1] }));
    });

    it('should allow to reclaim some shares', async function () {
      const tx = await shareDistribution.reclaimShares(10000);
      assert.equal(tx.receipt.status, '0x01', 'status');
    });

    it('should allow to reclaim all shares', async function () {
      const tx = await shareDistribution.reclaimShares(100000);
      assert.equal(tx.receipt.status, '0x01', 'status');
    });
  });
});
