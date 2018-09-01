
const assertThrow = require('../helpers/assertThrow');
const assertRevert = require('../helpers/assertRevert');

const SeizableTokenMock = artifacts.require('./mocks/SeizableTokenMock.sol');

contract('SeizableToken', function (accounts) {
  let token;
  const authority = accounts[2];

  beforeEach(async function () {
    token = await SeizableTokenMock.new(accounts[0], 100);

    await token.transfer(accounts[1], 50);
    const balance0 = await token.balanceOf(accounts[0]);
    const balance1 = await token.balanceOf(accounts[1]);
    assert.equal(balance0, 50);
    assert.equal(balance1, 50);

    const allTimeSeized = await token.allTimeSeized();
    assert.equal(allTimeSeized, 0);
  });

  it('should not allow owner to seize anything', async function () {
    await assertRevert(token.seize(accounts[1], 1));
  });

  it('should not allow any user to seize anything', async function () {
    await assertRevert(token.seize(accounts[0], 1, { from: accounts[1] }));
  });

  describe('with authority defined', function () {
    beforeEach(async function () {
      await token.defineAuthority('REGULATOR', authority);
    });

    it('should seize 1 from account', async function () {
      await token.seize(accounts[1], 1, { from: authority });

      const balance0 = await token.balanceOf(accounts[0]);
      const balance1 = await token.balanceOf(accounts[1]);
      assert.equal(balance0, 51);
      assert.equal(balance1, 49);
    });

    it('should seize everything from account', async function () {
      await token.seize(accounts[1], 50, { from: authority });

      const balance0 = await token.balanceOf(accounts[0]);
      const balance1 = await token.balanceOf(accounts[1]);
      assert.equal(balance0, 100);
      assert.equal(balance1, 0);
    });

    it('should increase allTimeSeize value', async function () {
      await token.seize(accounts[1], 10, { from: authority });
      const allTimeSeized1 = await token.allTimeSeized();
      assert.equal(allTimeSeized1, 10);

      await token.seize(accounts[1], 10, { from: authority });
      const allTimeSeized2 = await token.allTimeSeized();
      assert.equal(allTimeSeized2, 20);
    });

    it('should log an event when seizing 2', async function () {
      const receipt = await token.seize(accounts[1], 2, { from: authority });
      assert.equal(receipt.logs.length, 1);
      assert.equal(receipt.logs[0].event, 'Seize');
      assert.equal(receipt.logs[0].args.account, accounts[1]);
      assert.equal(receipt.logs[0].args.amount, 2);
    });

    it('should throw an error trying to seize more than account have', async function () {
      await assertThrow(token.seize(accounts[1], 1000, { from: authority }));
    });

    it('should revert trying to seize authority (self)', async function () {
      await assertRevert(token.seize(accounts[0], 1000, { from: authority }));
    });

    it('should not allow anyone other than authority to seize', async function () {
      await assertRevert(token.seize(accounts[1], 1000));
    });
  });
});
