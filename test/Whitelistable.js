'user strict';

const assertRevert = require('./helpers/assertRevert');

var Whitelist = artifacts.require('../contracts/Whitelist.sol');
var WhitelistableMock = artifacts.require('../contracts/WhitelistableMock.sol');

contract('Whitelistable', function (accounts) {
  let whitelist;
  let whitelistable;

  beforeEach(async function () {
    whitelist = await Whitelist.new([accounts[1], accounts[2]]);
    whitelistable = await WhitelistableMock.new();
  });

  it('should have no whitelist', async function () {
    const whitelistAddr = await whitelistable.whitelist();
    assert.equal(whitelistAddr, '0x0000000000000000000000000000000000000000');
  });

  it('should have a modifier blocking', async function () {
    await assertRevert(whitelistable.testMe());
  });

  it('should update the whitelist', async function () {
    const tx = await whitelistable.updateWhitelist(whitelist.address);
    assert.equal(tx.receipt.status, '0x01', 'Status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'WhitelistUpdated');
    assert.equal(tx.logs[0].args.whitelist, whitelist.address);
  });

  describe('with a whitelist configured', function () {
    beforeEach(async function () {
      await whitelistable.updateWhitelist(whitelist.address);
    });

    it('should returns the whitelist address', async function () {
      const whitelistAddr = await whitelistable.whitelist();
      assert.equal(whitelistAddr, whitelist.address, 'whitelistAddr');
    });

    it('should have the modifier working', async function () {
      const txApprove = await whitelist.approveAddress(accounts[0]);
      assert.equal(txApprove.receipt.status, '0x01', 'Status');
      const txIsWhitelisted = await whitelistable.testMe();
      assert.equal(txIsWhitelisted.receipt.status, '0x01', 'Status');

      const success = await whitelistable.success();
      assert.equal(success, true, 'modifier success');
    });
  });
});
