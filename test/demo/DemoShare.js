'user strict';

var DemoFiatToken = artifacts.require('../contracts/demo/DemoFiatToken.sol');
var DemoShare = artifacts.require('../contracts/demo/DemoShare.sol');

contract('DemoShare', function (accounts) {
  let demoToken;
  let demoShare;
  let tomorrow = (new Date().getTime() / 1000) + 24 * 3600;

  const delay = 1;
  async function waitDelay () {
    await new Promise(resolve => setTimeout(resolve, (delay + 1) * 1000));
  }

  beforeEach(async function () {
    demoToken = await DemoFiatToken.new('Name', 'SMB');
    demoShare = await DemoShare.new(demoToken.address);
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

      it('should closeVote and distribute dividend when enought approvals', async function () {
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
