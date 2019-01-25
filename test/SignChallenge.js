'user strict';

/**
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2019 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 */

const SignChallenge = artifacts.require('../contracts/SignChallenge.sol');
const ContractMock = artifacts.require('../contracts/mock/ContractMock.sol');

contract('SignChallenge', function (accounts) {
  let signChallenge;
  let contractMock;

  beforeEach(async function () {
    contractMock = await ContractMock.new();
    signChallenge = await SignChallenge.new();
  });

  it('should not accept a value transfer by default', async function () {
    const wei = web3.toWei(1, 'ether');
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: signChallenge.address,
      value: wei,
    }, (error, data) => {
      const revertFound = error.message.search('revert') >= 0;
      assert(revertFound, `Expected "revert", got ${error} instead`);
    });
  });

  it('should not accept a challenge too long', async function () {
    const validCode = '0x100000000';
    await web3.eth.sendTransaction({
      from: accounts[0],
      to: signChallenge.address,
      data: validCode,
      value: 0,
    }, (error, data) => {
      const revertFound = error.message.search('revert') >= 0;
      assert(revertFound, `Expected "revert", got ${error} instead`);
    });
  });

  it('should submit a challenge', async function () {
    const validCode = '0x12341234';
    const txHash = await web3.eth.sendTransaction({
      from: accounts[0],
      to: signChallenge.address,
      data: validCode,
      value: 0,
    });
    assert.ok(txHash, 'txHash');
  });

  it('should let execute transfer', async function () {
    const request = contractMock.testMe.request();
    const receipt = await signChallenge.execute(
      contractMock.address,
      request.params[0].data, { value: web3.toWei(0.1, 'ether') });

    assert.ok(receipt.tx);
    assert.equal(receipt.logs.length, 0);
  });
});
