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

const assertRevert = require('./helpers/assertRevert');
const PayableProxy = artifacts.require('../contracts/PayableProxy.sol');
const ContractMock = artifacts.require('../contracts/mock/ContractMock.sol');

contract('PayableProxy', function (accounts) {
  let payableProxy;
  let contractMock;
  let yersteday = Math.round(new Date().getTime() / 1000) - 24 * 3600;
  let tomorrow = Math.round(new Date().getTime() / 1000) + 24 * 3600;

  const defaultFunc = 'func(address, bytes)';
  const defaultFuncAbi = '0x9981f2a9';
  const defaultData = defaultFuncAbi.padEnd(34, '0') + accounts[0].substring(2);

  async function getLogs (watcher) {
    const promise = new Promise((resolve, reject) => {
      watcher.get((error, events) => {
        if (!error) {
          resolve(events);
        } else {
          reject(error);
        }
      });
    });
    return promise;
  }

  beforeEach(async function () {
    contractMock = await ContractMock.new();
    payableProxy = await PayableProxy.new(contractMock.address, defaultFunc, yersteday);
  });

  it('should provide the payable addr', async function () {
    const payableAddr = await payableProxy.payableAddr();
    assert.equal(payableAddr, contractMock.address, 'payableAddr');
  });

  it('should provide the payable function', async function () {
    const payableFunction = await payableProxy.payableFunction();
    assert.equal(payableFunction, '0x9981f2a9', 'payableFunction');
  });

  it('should provide the start datetime', async function () {
    const startAt = await payableProxy.startAt();
    assert.equal(startAt.toNumber(), yersteday, 'startAt');
  });

  it('should provide the lock status', async function () {
    const configLocked = await payableProxy.isConfigLocked();
    assert.equal(configLocked, false, 'configLocked');
  });

  it('should dryRun the call to payable', async function () {
    const tx = await payableProxy.dryRun();
    assert.equal(tx.receipt.status, '0x01', 'success');

    const events = await getLogs(contractMock.LogMsg());
    assert.equal(events.length, 1);
    assert.equal(events[0].event, 'LogMsg');
    assert.equal(events[0].args.sender, payableProxy.address, 'sender');
    assert.equal(events[0].args.origin, accounts[0], 'origin');
    assert.equal(web3.fromWei(events[0].args.value, 'ether').toNumber(), 0, 'value');
   
    const data = defaultData + web3.fromAscii('test').substring(2).padEnd(64, '0');
    assert.equal(events[0].args.data, data, 'data');
  });

  it('should lock the configuration', async function () {
    const tx = await payableProxy.lockConfig();
    assert.equal(tx.receipt.status, '0x01', 'status');
    assert.equal(tx.logs.length, 1, 'logs');
    assert.equal(tx.logs[0].event, 'ConfigLocked', 'log name');

    assert.equal(await payableProxy.isConfigLocked(), true, 'isConfigLocked');
  });

  describe('when still unlocked', function () {
    it('should reject value transfer', async function () {
      const wei = web3.toWei(1, 'ether');
      await web3.eth.sendTransaction({
        from: accounts[0],
        to: payableProxy.address,
        value: wei,
      }, (error, data) => {
        const revertFound = error.message.search('revert') >= 0;
        assert(revertFound, `Expected "revert", got ${error} instead`);
      });
    });

    it('should prevent non owner to redefined proxy', async function () {
      await assertRevert(payableProxy.configure('0x0', '0', tomorrow, { from: accounts[1] }));
    });

    it('should let owner redefined the proxy', async function () {
      const tx = await payableProxy.configure('0x0', '0', tomorrow);
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 1, 'logs');
      assert.equal(tx.logs[0].event, 'NewConfig', 'log name');
      assert.equal(tx.logs[0].args.payableAddr, '0x0000000000000000000000000000000000000000', 'payableAddr');
      assert.equal(tx.logs[0].args.payableAbi, '0', 'payableFunc');
      assert.equal(tx.logs[0].args.startAt.toNumber(), tomorrow, 'startAt');

      assert.equal(await payableProxy.payableAddr(), '0x0000000000000000000000000000000000000000', 'payableAddr');
      assert.equal(await payableProxy.payableFunction(), '0x044852b2', 'payableFunc');
      assert.equal(await payableProxy.startAt(), tomorrow, 'startAt');
    });
  });

  describe('when locked', function () {
    beforeEach(async function () {
      await payableProxy.lockConfig();
    });

    it('should accept value transfer', async function () {
      const wei = web3.toWei(1, 'ether');
      const txHash = await web3.eth.sendTransaction({
        from: accounts[0],
        to: payableProxy.address,
        value: wei,
      });
      assert.ok(txHash, 'txHash');

      const events = await getLogs(contractMock.LogMsg());
      assert.equal(events.length, 1);
      assert.equal(events[0].event, 'LogMsg');
      assert.equal(events[0].args.sender, payableProxy.address, 'sender');
      assert.equal(events[0].args.origin, accounts[0], 'origin');
      assert.equal(web3.fromWei(events[0].args.value, 'ether').toNumber(), 1, 'value');

      assert.equal(events[0].args.data, defaultData, 'data');
    });

    describe('and chain with a second locked proxy', function () {
      let callingContract;

      const emptyFunc = '';
      const emptyFuncAbi = '0xc5d24601';

      beforeEach(async function () {
        callingContract = await PayableProxy.new(payableProxy.address, emptyFunc, yersteday);
        await callingContract.lockConfig();
      });

      it('should accept and have correct sender/origin/data', async function () {
        const txHash = await web3.eth.sendTransaction({
          from: accounts[0],
          to: callingContract.address,
          value: web3.toWei(1, 'ether'),
        });
        assert.ok(txHash, 'txHash');

        const events = await getLogs(contractMock.LogMsg());
        assert.equal(events.length, 1);
        assert.equal(events[0].event, 'LogMsg');
        assert.equal(events[0].args.sender, payableProxy.address, 'sender');
        assert.equal(events[0].args.origin, accounts[0], 'origin');
        assert.equal(web3.fromWei(events[0].args.value, 'ether').toNumber(), 1, 'value');

        const callingContractData = emptyFuncAbi.substring(2).padEnd(32, '0') + accounts[0].substring(2);
        const data = defaultFuncAbi.padEnd(34, '0') +
          callingContract.address.substring(2).padEnd(10, '0') +
          callingContractData.padEnd(128, '0');
        assert.equal(events[0].args.data, data, 'data');
      });
    });
  });
});
