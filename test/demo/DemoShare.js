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
const DemoFiatToken = artifacts.require('../contracts/demo/DemoFiatToken.sol');
const DemoShare = artifacts.require('../contracts/demo/DemoShare.sol');

contract('DemoShare', function (accounts) {
  let demoToken;
  let demoShare;

  const now = (new Date().getTime() / 1000);
  const tomorrow = (new Date().getTime() / 1000) + 24 * 3600;

  const delay = 1;
  async function waitDelay () {
    await new Promise(resolve => setTimeout(resolve, (delay + 1) * 1000));
  }

  beforeEach(async function () {
    demoToken = await DemoFiatToken.new('Name', 'SMB');
    demoShare = await DemoShare.new(demoToken.address);
  });

  it('should have a token', async function () {
    const tokenAddress = await demoShare.token();
    assert.equal(tokenAddress, demoToken.address, 'token address');
  });

  it('should allow owner token update', async function () {
    const tx = await demoShare.updateToken(0);
    assert.equal(tx.receipt.status, '0x01', 'status');
  });

  it('should prevent non owner to update token', async function () {
    await assertRevert(demoShare.updateToken(0, { from: accounts[1] }));
  });

  it('should have 0 proposals', async function () {
    const count = await demoShare.currentProposalId();
    assert.equal(count.toNumber(), 0, 'count');
  });

  it('should have no url', async function () {
    const url = await demoShare.currentUrl();
    assert.equal(url, '', 'url');
  });

  it('should have no hash', async function () {
    const hash = await demoShare.currentHash();
    assert.equal(hash, 0, 'hash');
  });

  it('should have no dividend token', async function () {
    const dividendToken = await demoShare.currentDividendToken();
    assert.equal(dividendToken, '0x0000000000000000000000000000000000000000', 'dividend token');
  });

  it('should have no started date', async function () {
    const startedAt = await demoShare.startedAt();
    assert.equal(startedAt.toNumber(), 0, 'started at');
  });

  it('should have no closed date', async function () {
    const closedAt = await demoShare.closedAt();
    assert.equal(closedAt.toNumber(), 0, 'closed at');
  });

  it('should have no vote approvals', async function () {
    const voteApprovals = await demoShare.voteApprovals();
    assert.equal(voteApprovals.toNumber(), 0, 'vote approvals');
  });

  it('should have no vote rejections', async function () {
    const voteRejections = await demoShare.voteRejections();
    assert.equal(voteRejections.toNumber(), 0, 'vote rejections');
  });

  describe('with demoToken issued and shareholders KYC-ed', function () {
    beforeEach(async function () {
      await demoToken.issue(5000);
      await demoToken.validateManyKYCUntil(accounts, tomorrow);
      await demoShare.updateShareholders(accounts);

      await demoToken.transfer(accounts[1], 2000);
      await demoToken.transfer(accounts[2], 3000);
    });

    it('should create a vote', async function () {
      const receipt = await demoShare.proposeVote('http://abcdef.gh', 0x123456, demoToken.address);

      assert.equal(receipt.logs.length, 1);
      assert.equal(receipt.logs[0].event, 'NewProposal');
      assert.equal(receipt.logs[0].args.proposalId, 0);
    });

    describe('and an active proposal', async function () {
      beforeEach(async function () {
        await demoShare.proposeVote('https://abcdef.gh', 0x123456, demoToken.address);
      });

      it('should have 1 proposals', async function () {
        const count = await demoShare.currentProposalId();
        assert.equal(count.toNumber(), 0, 'count');
      });

      it('should have an url', async function () {
        const url = await demoShare.currentUrl();
        assert.equal(url, 'https://abcdef.gh', 'url');
      });

      it('should have a hash', async function () {
        const hash = await demoShare.currentHash();
        assert.equal(hash, 0x123456, 'hash');
      });

      it('should have a dividend token', async function () {
        const dividendToken = await demoShare.currentDividendToken();
        assert.equal(dividendToken, demoToken.address, 'dividend token');
      });

      it('should have a started date defined', async function () {
        const startedAt = await demoShare.startedAt();
        assert.ok(startedAt >= now, 'started at');
      });

      it('should have a closed date at infinity', async function () {
        const closedAt = await demoShare.closedAt();
        assert.equal(
          closedAt.toNumber(),
          web3.toBigNumber(
            '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
          ).toNumber(),
          'closed at');
      });

      it('should have no vote approvals', async function () {
        const voteApprovals = await demoShare.voteApprovals();
        assert.equal(voteApprovals.toNumber(), 0, 'vote approvals');
      });

      it('should have no vote rejections', async function () {
        const voteRejections = await demoShare.voteRejections();
        assert.equal(voteRejections.toNumber(), 0, 'vote rejections');
      });

      it('should closeVote and distribute dividend when enough approvals', async function () {
        await demoShare.approveProposal({ from: accounts[2] });
        const receipt = await demoShare.closeVote();
        assert.equal(receipt.logs.length, 1);
        assert.equal(receipt.logs[0].event, 'Approved');
        assert.equal(receipt.logs[0].args.proposalId, 0);
        assert.equal(receipt.logs[0].args.total, 5000);
        assert.equal(receipt.logs[0].args.approvals, 3000);
        assert.equal(receipt.logs[0].args.rejections, 0);
  
        const hasVoted = await demoShare.hasVoted(accounts[2]);
        assert.ok(hasVoted);

        await waitDelay();
  
        const receiptDistribute = await demoShare.distribute();
        assert.equal(receiptDistribute.logs.length, 1);
        assert.equal(receiptDistribute.logs[0].event, 'Distribution');
        assert.equal(receiptDistribute.logs[0].args.proposalId.toNumber(), 0);
        assert.equal(receiptDistribute.logs[0].args.token, demoToken.address);
        assert.equal(receiptDistribute.logs[0].args.dividendAmount, 0);
      });

      it('should closeVote and return the dividend to the owner when not enougth approvals', async function () {
        await demoShare.rejectProposal({ from: accounts[2] });
        const receipt = await demoShare.closeVote();
        assert.equal(receipt.logs[0].event, 'Rejected');
        assert.equal(receipt.logs[0].args.proposalId, 0);
        assert.equal(receipt.logs[0].args.total, 5000);
        assert.equal(receipt.logs[0].args.approvals, 0);
        assert.equal(receipt.logs[0].args.rejections, 3000);

        const hasVoted = await demoShare.hasVoted(accounts[2]);
        assert.ok(hasVoted);
      });
    });
  });
});
