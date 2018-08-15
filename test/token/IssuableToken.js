'user strict';

const assertThrow = require('../helpers/assertThrow');
const assertRevert = require('../helpers/assertRevert');

var IssuableTokenMock = artifacts.require('mocks/IssuableTokenMock.sol');

contract('IssuableToken', function (accounts) {
  let token;

  beforeEach(async function () {
    token = await IssuableTokenMock.new(accounts[0], 100);

    await assertSupplyState(100, 100, 100, 0);
  });

  async function assertSupplyState (_totalSupply, _ownerBalance, _allTimeIssued, _allTimeRedeemed) {
    let totalSupply = await token.totalSupply();
    assert.equal(totalSupply, _totalSupply, 'totalSupply');
    
    let balance0 = await token.balanceOf(accounts[0]);
    assert.equal(balance0, _ownerBalance, 'ownerBalance');

    let allTimeIssued = await token.allTimeIssued();
    assert.equal(allTimeIssued, _allTimeIssued, 'allTimeIssued');

    let allTimeRedeemed = await token.allTimeRedeemed();
    assert.equal(allTimeRedeemed, _allTimeRedeemed, 'allTimeRedeemed');
  };

  it('should issue 1', async function () {
    await token.issue(1);
    await assertSupplyState(101, 101, 101, 0);
  });

  it('should redeem 1', async function () {
    await token.redeem(1);
    await assertSupplyState(99, 99, 100, 1);
  });

  it('should log an event when issuing 2', async function () {
    const receipt = await token.issue(2);
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'Issued');
    assert.equal(receipt.logs[0].args.amount, 2);
  });

  it('should log an event when redeeming 2', async function () {
    const receipt = await token.redeem(2);
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'Redeemed');
    assert.equal(receipt.logs[0].args.amount, 2);
  });

  it('should throw an error trying to redeem more than owner have', async function () {
    await assertThrow(token.redeem(1000));
  });

  it('should not allow other than owner to issue', async function () {
    await assertRevert(token.issue(1000, { from: accounts[1] }));
  });

  it('should not allow other than owner to redeem', async function () {
    await assertRevert(token.redeem(1000, { from: accounts[1] }));
  });
});
