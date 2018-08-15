'user strict';

var TokenWithClaims = artifacts.require('../contracts/mock/TokenWithClaimsMock.sol');
var TokenizedVotingClaimable = artifacts.require('../contracts/voting/TokenizedVotingClaimable.sol');

contract('TokenizedVotingClaimable', function (accounts) {
  let votingClaimable;
  let token;

  const expectedQuestion = 'Would you like to vote ?';
  const expectedHash = web3.sha3('alphabet', { encoding: 'hex' });
  const expectedUrl = 'http://url.url';
  const before = Math.floor((new Date()).getTime() / 1000);
 
  beforeEach(async function () {
    token = await TokenWithClaims.new([], accounts[0], 10000);
    await token.transfer(accounts[1], 200);
    votingClaimable = await TokenizedVotingClaimable.new(token.address);
    await token.addClaimable(votingClaimable.address);
  });

  it('should have no claims', async function () {
    const hasClaims = await votingClaimable.hasClaimsSince(accounts[1], before);
    assert.ok(!hasClaims, 'hasClaims');
  });

  describe('with a vote on going', function () {
    beforeEach(async function () {
      await votingClaimable.addProposal(expectedQuestion, expectedUrl, expectedHash, 2);
    });

    it('should have claims since a date before the proposal creation', async function () {
      const hasClaims = await votingClaimable.hasClaimsSince(accounts[1], before);
      assert.ok(hasClaims, 'hasClaims');
    });

    it('should have no claims since a date after the proposal creation', async function () {
      const hasClaims = await votingClaimable.hasClaimsSince(accounts[1], before + 3600);
      assert.ok(!hasClaims, 'hasClaims');
    });
  });
});
