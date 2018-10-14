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

const TokenWithClaims = artifacts.require('../contracts/mock/TokenWithClaimsMock.sol');
const TokenizedVotingWithRulesClaimable =
  artifacts.require('../contracts/voting/TokenizedVotingWithRulesClaimable.sol');

contract('TokenizedVotingWithRulesClaimable', function (accounts) {
  let votingWithRulesClaimable;
  let token;

  const expectedQuestion = 'Would you like to vote ?';
  const expectedHash = web3.sha3('alphabet', { encoding: 'hex' });
  const expectedUrl = 'http://url.url';
  const before = Math.floor((new Date()).getTime() / 1000);
 
  beforeEach(async function () {
    token = await TokenWithClaims.new([], accounts[0], 10000);
    await token.transfer(accounts[1], 200);
    votingWithRulesClaimable = await TokenizedVotingWithRulesClaimable.new(token.address, []);
    await token.defineClaimables([ votingWithRulesClaimable.address ]);
  });

  it('should have no claims', async function () {
    const hasClaims = await votingWithRulesClaimable.hasClaimsSince(accounts[1], before);
    assert.ok(!hasClaims, 'hasClaims');
  });

  describe('with a vote on going', function () {
    beforeEach(async function () {
      await votingWithRulesClaimable.addProposal(expectedQuestion, expectedUrl, expectedHash, 2);
    });

    it('should have claims since a date before the proposal creation', async function () {
      const hasClaims = await votingWithRulesClaimable.hasClaimsSince(accounts[1], before);
      assert.ok(hasClaims, 'hasClaims');
    });

    it('should have no claims since a date after the proposal creation', async function () {
      const hasClaims = await votingWithRulesClaimable.hasClaimsSince(accounts[1], before + 3600);
      assert.ok(!hasClaims, 'hasClaims');
    });
  });
});
