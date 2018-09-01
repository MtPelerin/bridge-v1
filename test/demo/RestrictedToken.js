'User strict';

const assertRevert = require('../helpers/assertRevert');

var RestrictedTokenMock = artifacts.require('../contracts/demo/RestrictedTokenMock.sol');

contract('RestrictedToken', function (accounts) {
  let token;

  const tomorrow = (new Date().getTime() / 1000) + 24 * 3600;

  beforeEach(async function () {
    token = await RestrictedTokenMock.new(accounts[0], 10 ** 20);
  });

  it('should not allow transfer from initial account', async function () {
    await assertRevert(token.transfer(accounts[1], 1000000));
  });

  it('should not allow transferFrom from initial account', async function () {
    await token.approve(accounts[1], 1000000);
    await assertRevert(token.transferFrom(accounts[0], accounts[1], 10000, { from: accounts[1] }));
  });
 
  describe('with initial account KYCed', function () {
    beforeEach(async function () {
      await token.validateKYCUntil(accounts[0], tomorrow);
    });

    it('should not allow transfer from initial account', async function () {
      await assertRevert(token.transfer(accounts[1], 1000000));
    });

    it('should not allow transferFrom from initial account', async function () {
      await token.approve(accounts[1], 1000000);
      await assertRevert(token.transferFrom(accounts[0], accounts[1], 10000, { from: accounts[1] }));
    });
  });

  describe('with initial account and recipient KYCed', function () {
    beforeEach(async function () {
      await token.validateManyKYCUntil([ accounts[0], accounts[1] ], tomorrow);
    });

    it('should allow transfer from initial account', async function () {
      const tx = await token.transfer(accounts[1], 1000000);
      assert.equal(tx.receipt.status, '0x01', 'status');
    });

    it('should let initial account approve', async function () {
      const increased = await token.approve(accounts[3], 1000000);
      assert.equal(increased.receipt.status, '0x01', 'increased');
    });

    it('should allow transferFrom from initial account', async function () {
      const increased = await token.approve(accounts[2], 1000000);
      assert.equal(increased.receipt.status, '0x01', 'increased');
      await assertRevert(token.transferFrom(
        accounts[0], accounts[1], 10000, { from: accounts[2] }));
    });
  });

  describe('with initial account, recipient and msg.sender KYCed', function () {
    beforeEach(async function () {
      await token.validateManyKYCUntil([ accounts[0], accounts[1], accounts[2] ], tomorrow);
    });

    it('should allow transferFrom from initial account', async function () {
      const increased = await token.approve(accounts[2], 1000000);
      assert.equal(increased.receipt.status, '0x01', 'increased');
      const tx = await token.transferFrom(
        accounts[0], accounts[1], 10000, { from: accounts[2] });
      assert.equal(tx.receipt.status, '0x01', 'status');
    });
  });
});
