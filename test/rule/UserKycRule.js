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

const UserRegistry = artifacts.require('../../contracts/UserRegistry.sol');
const UserKycRule = artifacts.require('../../contracts/rule/UserKycRule.sol');

contract('UserKycRule', function (accounts) {
  let userRegistry, rule;
  
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;
  const dayMinusOneTime = Math.floor((new Date()).getTime() / 1000) - 3600 * 24;
  const userAddresses = [ accounts[0], accounts[1], accounts[2], accounts[3], accounts[4], accounts[5] ];

  beforeEach(async function () {
    userRegistry = await UserRegistry.new(userAddresses, dayPlusOneTime);
    await userRegistry.defineOperators([ 'OPERATOR' ], [ accounts[0] ]);
    rule = await UserKycRule.new(userRegistry.address);
    await userRegistry.suspendManyUsers([ 3, 4 ]); // userId of accounts[2] and accounts[3]
    await userRegistry.updateManyUsers([ 5, 6 ], dayMinusOneTime, false); // userId of accounts[4] and accounts[5]
  });

  async function isAddressValid (address, expected) {
    const isAddressValid = await rule.isAddressValid(address);
    assert.ok(isAddressValid === expected, 'valid');
  };

  async function isTransferValid (sender, receiver, expected) {
    const isTransferValid = await rule.isTransferValid(sender, receiver, 100);
    assert.ok(isTransferValid === expected, 'valid');
  };

  it('should have a user registry', async function () {
    const userRegistryAddr = await rule.userRegistry();
    assert.equal(userRegistryAddr, userRegistry.address, 'User registry');
  });

  it('should be valid for the address of a valid user', async function () {
    await isAddressValid(accounts[0], true);
  });

  it('should be invalid for the address of a lock user', async function () {
    await isAddressValid(accounts[3], false);
  });

  it('should be invalid for the address of a user not valid anymore', async function () {
    await isAddressValid(accounts[5], false);
  });

  it('should be valid for transfer with both valid user', async function () {
    await isTransferValid(accounts[0], accounts[1], true);
  });

  it('should be invalid for transfer with receiver locked', async function () {
    await isTransferValid(accounts[0], accounts[2], false);
  });

  it('should be invalid for transfer with sender locked', async function () {
    await isTransferValid(accounts[2], accounts[0], false);
  });

  it('should be invalid for transfer with sender and receiver locked', async function () {
    await isTransferValid(accounts[2], accounts[3], false);
  });

  it('should be invalid for transfer with receiver not valid anymore', async function () {
    await isTransferValid(accounts[0], accounts[4], false);
  });

  it('should be invalid for transfer with sender not valid anymore', async function () {
    await isTransferValid(accounts[4], accounts[0], false);
  });

  it('should be invalid for transfer with sender and receiver not valid anymore', async function () {
    await isTransferValid(accounts[4], accounts[5], false);
  });
});
