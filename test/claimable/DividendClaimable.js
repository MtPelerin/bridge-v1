'user strict';

var TokenWithClaims = artifacts.require('./contracts/mock/TokenWithClaimsMock.sol');
var DividendClaimable = artifacts.require('./contracts/dividend/DividendClaimable.sol');

contract('DividendClaimable', function (accounts) {
  let dividendClaimable;
  let token;

  const delay = 1;
  async function waitDelay () {
    await new Promise(resolve => setTimeout(resolve, (delay + 1) * 1000));
  }

  const before = Math.floor((new Date()).getTime() / 1000);
 
  beforeEach(async function () {
    token = await TokenWithClaims.new([], accounts[0], 10000);
    await token.transfer(accounts[1], 200);
    dividendClaimable = await DividendClaimable.new(token.address);
    await token.addClaimable(dividendClaimable.address);
  });

  it('should have no claims', async function () {
    const hasClaims = await dividendClaimable.hasClaimsSince(accounts[1], before);
    assert.ok(!hasClaims, 'hasClaims');
  });

  describe('with a past dividend', function () {
    beforeEach(async function () {
      await token.approve(dividendClaimable.address, 100);
      await dividendClaimable.createDividend(token.address, accounts[0], 100);
      await waitDelay();
    });

    it('should have claims since a date before the proposal creation', async function () {
      const hasClaims = await dividendClaimable.hasClaimsSince(accounts[1], before);
      assert.ok(hasClaims, 'hasClaims');
    });

    it('should have no claims since a date after the proposal creation', async function () {
      const hasClaims = await dividendClaimable.hasClaimsSince(accounts[1], before + 3600);
      assert.ok(!hasClaims, 'hasClaims');
    });
  });
});
