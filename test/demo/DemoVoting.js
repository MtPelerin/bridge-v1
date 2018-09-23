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

const DemoVoting = artifacts.require('demo/DemoVoting.sol');
const StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');

contract('DemoShare', function (accounts) {
  let token, voting;
  let now = (new Date().getTime() / 1000);

  beforeEach(async function () {
    token = await StandardTokenMock.new(accounts[0], 1000);
    voting = await DemoVoting.new(token.address);

    await token.transfer(accounts[1], 400);
  });

  it('should have a voting token', async function () {
    const tokenAddr = await voting.votingToken();
    assert.equal(tokenAddr, token.address, 'voting token');
  });

  it('should have a current proposal Id to 0', async function () {
    const proposalId = await voting.currentProposalId();
    assert.equal(proposalId, 0, 'proposalId');
  });

  it('should propose a new vote', async function () {
    const tx = await voting.proposeVote('https://mtpelerin.com', '0x123456');
    assert.equal(tx.receipt.status, '0x1');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'NewProposal');
    assert.equal(tx.logs[0].args.proposalId, 1);
  });

  describe('with an active proposal', function () {
    beforeEach(async function () {
      await voting.proposeVote('https://mtpelerin.com', '0x123456');
    });

    it('should have a current proposalId', async function () {
      const proposalId = await voting.currentProposalId();
      assert.equal(proposalId, 1, 'proposalId');
    });

    it('should have a current vote Url', async function () {
      const url = await voting.currentUrl();
      assert.equal(url, 'https://mtpelerin.com', 'url');
    });

    it('should have a current hash', async function () {
      const hash = await voting.currentHash();
      assert.equal(hash.toNumber(), '0x123456', 'hash');
    });

    it('should have a start date', async function () {
      const startDate = await voting.startedAt();
      assert.ok(startDate >= now, 'start date');
    });

    it('should have a close date', async function () {
      const closeDate = await voting.closedAt();
      assert.equal(closeDate.toNumber(),
        web3.toBigNumber(
          '0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff'
        ).toNumber(),
        'closed at');
    });

    it('should have 0 approvals', async function () {
      const approvals = await voting.voteApprovals();
      assert.equal(approvals, 0, 'approvals');
    });

    it('should have 0 rejections', async function () {
      const rejections = await voting.voteRejections();
      assert.equal(rejections, 0, 'rejections');
    });

    it('should returns that no one has voted', async function () {
      const hasVoted0 = await voting.hasVoted(accounts[0]);
      assert.ok(!hasVoted0, 'hasVoted account 0');

      const hasVoted1 = await voting.hasVoted(accounts[1]);
      assert.ok(!hasVoted1, 'hasVoted account 1');
    });

    it('should let holder to approve', async function () {
      const tx = await voting.approveProposal();
      assert.equal(tx.receipt.status, '0x1');
 
      const approvals = await voting.voteApprovals();
      assert.equal(approvals.toNumber(), 600, 'approvals');
      const rejections = await voting.voteRejections();
      assert.equal(rejections.toNumber(), 0, 'approvals');

      const hasVoted = await voting.hasVoted(accounts[0]);
      assert.ok(hasVoted, 'hasVoted');
    });

    it('should let holder to reject', async function () {
      const tx = await voting.rejectProposal();
      assert.equal(tx.receipt.status, '0x1');
 
      const approvals = await voting.voteApprovals();
      assert.equal(approvals.toNumber(), 0, 'approvals');
      const rejections = await voting.voteRejections();
      assert.equal(rejections.toNumber(), 600, 'approvals');

      const hasVoted = await voting.hasVoted(accounts[0]);
      assert.ok(hasVoted, 'hasVoted');
    });

    it('should close vote', async function () {
      const tx = await voting.closeVote();
      assert.equal(tx.receipt.status, '0x1');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Rejected');
      assert.equal(tx.logs[0].args.proposalId, 1);
      assert.equal(tx.logs[0].args.total.toNumber(), 1000);
      assert.equal(tx.logs[0].args.approvals.toNumber(), 0);
      assert.equal(tx.logs[0].args.rejections.toNumber(), 0);
    });

    describe('with enougth approvals', function () {
      beforeEach(async function () {
        await voting.approveProposal();
        await voting.rejectProposal({ from: accounts[1] });
      });

      it('should close vote and approve', async function () {
        const tx = await voting.closeVote();
        assert.equal(tx.receipt.status, '0x1');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'Approved');
        assert.equal(tx.logs[0].args.proposalId, 1);
        assert.equal(tx.logs[0].args.total.toNumber(), 1000);
        assert.equal(tx.logs[0].args.approvals.toNumber(), 600);
        assert.equal(tx.logs[0].args.rejections.toNumber(), 400);
      });
    });

    describe('with enougth rejections', function () {
      beforeEach(async function () {
        await voting.approveProposal({ from: accounts[1] });
        await voting.rejectProposal();
      });

      it('should close vote and reject', async function () {
        const tx = await voting.closeVote();
        assert.equal(tx.receipt.status, '0x1');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'Rejected');
        assert.equal(tx.logs[0].args.proposalId, 1);
        assert.equal(tx.logs[0].args.total.toNumber(), 1000);
        assert.equal(tx.logs[0].args.approvals.toNumber(), 400);
        assert.equal(tx.logs[0].args.rejections.toNumber(), 600);
      });
    });
  });
});
