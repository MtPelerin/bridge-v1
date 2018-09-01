'user strict';

var FreezeRule = artifacts.require('../../contracts/rule/FreezeRule.sol');

contract('FreezeRule', function (accounts) {
  let rule;
  
  const authority = accounts[1];
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;
  const dayMinusOneTime = Math.floor((new Date()).getTime() / 1000) - 3600 * 24;

  beforeEach(async function () {
    rule = await FreezeRule.new();
    await rule.defineAuthority('REGULATOR', authority);
    await rule.freezeAddresses([ accounts[2], accounts[3] ], dayPlusOneTime, { from: authority });
    await rule.freezeAddresses([ accounts[4], accounts[5] ], dayMinusOneTime, { from: authority });
  });

  async function isAddressValid (address, expected) {
    const isAddressValid = await rule.isAddressValid(address);
    assert.ok(isAddressValid === expected, 'valid');
  };

  async function isTransferValid (sender, receiver, expected) {
    const isTransferValid = await rule.isTransferValid(sender, receiver, 100);
    assert.ok(isTransferValid === expected, 'valid');
  };

  it('should be valid for the address of a valid user', async function () {
    await isAddressValid(accounts[0], true);
  });

  it('should be invalid for the address of a lock user', async function () {
    await isAddressValid(accounts[3], false);
  });

  it('should be valid for the address of a user no more frozen', async function () {
    await isAddressValid(accounts[5], true);
  });

  it('should be valid for transfer with both valid user', async function () {
    await isTransferValid(accounts[0], accounts[1], true);
  });

  it('should be invalid for transfer with receiver frozen', async function () {
    await isTransferValid(accounts[0], accounts[2], false);
  });

  it('should be invalid for transfer with sender frozen', async function () {
    await isTransferValid(accounts[2], accounts[0], false);
  });

  it('should be invalid for transfer with sender and receiver frozen', async function () {
    await isTransferValid(accounts[2], accounts[3], false);
  });

  it('should be valid for transfer with receiver no more invalid', async function () {
    await isTransferValid(accounts[0], accounts[4], true);
  });

  it('should be valid for transfer with sender no more invalid', async function () {
    await isTransferValid(accounts[4], accounts[0], true);
  });

  it('should be valid for transfer with sender and receiver no more invalid', async function () {
    await isTransferValid(accounts[4], accounts[5], true);
  });
});
