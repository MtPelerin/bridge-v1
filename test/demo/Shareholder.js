'user strict';

const assertRevert = require('../helpers/assertRevert');

var Shareholder = artifacts.require('../contracts/demo/Shareholder.sol');

contract('Shareholder', function (accounts) {
  let shareholder;

  beforeEach(async function () {
    shareholder = await Shareholder.new();
  });

  it('should have no shareholders', async function () {
    const shareholders = await shareholder.shareholders();
    assert.equal(shareholders.length, 0);
  });

  it('should return false for isShareholder', async function () {
    const isShareholder = await shareholder.isShareholder(accounts[1]);
    assert.ok(!isShareholder, 'not shareholder');
  });

  it('should be possible for owner to update shareholders', async function () {
    const tx = await shareholder.updateShareholders([ accounts[1], accounts[2] ]);
    assert.equal(tx.receipt.status, '0x01', 'status');
  });

  it('should not be possible for non owner to update shareholders', async function () {
    await assertRevert(
      shareholder.updateShareholders(
        [ accounts[1], accounts[2] ], { from: accounts[1] }
      )
    );
  });

  describe('with some shareholders', function () {
    beforeEach(async function () {
      await shareholder.updateShareholders([ accounts[1], accounts[2] ]);
    });

    it('should have 2 shareholders', async function () {
      const shareholders = await shareholder.shareholders();
      assert.equal(shareholders.length, 2);
    });

    it('should return true for isShareholder if address is shareholder', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[1]);
      assert.ok(isShareholder, 'is shareholder');
    });

    it('should return false for isShareholder if address is owner', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[0]);
      assert.ok(!isShareholder, 'owner is not shareholder');
    });

    it('should return false for isShareholder if address is non shareholder or non owner', async function () {
      const isShareholder = await shareholder.isShareholder(accounts[5]);
      assert.ok(!isShareholder, 'not shareholder');
    });
  });
});
