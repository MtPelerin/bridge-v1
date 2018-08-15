'user strict';

const assertRevert = require('../helpers/assertRevert');

var MintableToken = artifacts.require('token/MintableToken.sol');

contract('MintableToken', function (accounts) {
  let token;

  beforeEach(async function () {
    token = await MintableToken.new();
  });

  it('should not have the minting finished', async function () {
    const finished = await token.mintingFinished();
    assert.equal(finished, false, 'finished');
  });

  it('should be able to mint as owner', async function () {
    const receipt = await token.mint(accounts[2], 100);
    assert.equal(receipt.logs.length, 2);
    assert.equal(receipt.logs[0].event, 'Mint');
    assert.equal(receipt.logs[0].args.to, accounts[2]);
    assert.equal(receipt.logs[0].args.amount, 100);

    assert.equal(receipt.logs[1].event, 'Transfer');
    assert.equal(receipt.logs[1].args.from, 0);
    assert.equal(receipt.logs[1].args.to, accounts[2]);
    assert.equal(receipt.logs[1].args.value, 100);
  });

  it('should not be able to mint as non owner', async function () {
    await assertRevert(token.mint(accounts[2], 100, { from: accounts[1] }));
  });

  it('should be able to finish minting as owner', async function () {
    const receipt = await token.finishMinting();
    assert.equal(receipt.logs.length, 1);
    assert.equal(receipt.logs[0].event, 'MintFinished');
  });

  it('should not be able to finish minting as non owner', async function () {
    await assertRevert(token.finishMinting({ from: accounts[1] }));
  });

  describe('with the minting finished', function () {
    beforeEach(async function () {
      await token.finishMinting();
    });

    it('should have the minting finished', async function () {
      const finished = await token.mintingFinished();
      assert.equal(finished, true, 'finished');
    });

    it('should not be able to mint as owner', async function () {
      await assertRevert(token.mint(accounts[2], 100));
    });

    it('should not be able to mint as non owner', async function () {
      await assertRevert(token.mint(accounts[2], 100, { from: accounts[1] }));
    });

    it('should not be able to finish minting a second time', async function () {
      await assertRevert(token.finishMinting());
    });
  });
});
