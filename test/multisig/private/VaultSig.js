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

const assertRevert = require('../../helpers/assertRevert');
const VaultSig = artifacts.require('../contracts/multisig/private/VaultSig.sol');
const StandardTokenMock = artifacts.require('mock/StandardTokenMock.sol');

contract('VaultSig', function (accounts) {
  let vaultSig;

  let sign = async function (address) {
    const hash = await vaultSig.replayProtection();
    const signedHash = web3.eth.sign(address, hash);

    return {
      r: '0x' + signedHash.slice(2).slice(0, 64),
      s: '0x' + signedHash.slice(2).slice(64, 128),
      v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
    };
  };

  describe('with one address and a threshold of 2', function () {
    beforeEach(async function () {
      vaultSig = await VaultSig.new([ accounts[1] ], 2);
    });

    it('should not execute ERC20 transfer', async function () {
      const token = await StandardTokenMock.new(vaultSig.address, 1000);
      const request = token.transfer.request(accounts[0], 100);
      const rsv = await sign(accounts[1]);

      await assertRevert(vaultSig.execute([ rsv.r ], [ rsv.s ], [ rsv.v ],
        request.params[0].to, 0, request.params[0].data));
    });
  });

  describe('with one address and threshold of 1', function () {
    beforeEach(async function () {
      vaultSig = await VaultSig.new([ accounts[1] ], 1);
      await new Promise(
        (resolve, reject) => web3.eth.sendTransaction({
          from: accounts[9],
          to: vaultSig.address,
          value: web3.toWei(1, 'gwei'),
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        })
      );
    });

    it('should not accept data with ETH in the same transaction', async function () {
      await assertRevert(new Promise(
        (resolve, reject) => web3.eth.sendTransaction({
          from: accounts[0],
          to: vaultSig.address,
          value: 1,
          data: 'abc',
        }, (err, data) => {
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        })
      ));
    });
 
    it('should transfer ETH', async function () {
      const rsv = await sign(accounts[1]);
      const tx = await vaultSig.transfer([ rsv.r ], [ rsv.s ], [ rsv.v ],
        accounts[0], 1);
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Execution');
      assert.equal(tx.logs[0].args.to, accounts[0], 'to');
      assert.equal(tx.logs[0].args.value.toNumber(), 1, 'value');
      assert.equal(tx.logs[0].args.data, '0x', 'data');
    });

    it('should transfer ERC20', async function () {
      const token = await StandardTokenMock.new(vaultSig.address, 1000);
      const request = token.transfer.request(accounts[0], 100);
      const rsv = await sign(accounts[1]);

      const tx = await vaultSig.transferERC20([ rsv.r ], [ rsv.s ], [ rsv.v ],
        token.address, accounts[0], 100);
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Execution');
      assert.equal(tx.logs[0].args.to, token.address, 'to');
      assert.equal(tx.logs[0].args.value, 0, 'value');
      assert.equal(tx.logs[0].args.data, request.params[0].data, 'data');
 
      const balance = await token.balanceOf(vaultSig.address);
      assert.equal(balance, 900, 'balance multisig');
      const balance0 = await token.balanceOf(accounts[0]);
      assert.equal(balance0, 100, 'balance account 0');
    });

    it('should execute ETH transfer', async function () {
      const rsv = await sign(accounts[1]);
      const tx = await vaultSig.execute([ rsv.r ], [ rsv.s ], [ rsv.v ],
        accounts[0], 1, '');
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Execution');
      assert.equal(tx.logs[0].args.to, accounts[0], 'to');
      assert.equal(tx.logs[0].args.value.toNumber(), 1, 'value');
      assert.equal(tx.logs[0].args.data, '0x', 'data');
    });

    it('should execute ERC20 transfer', async function () {
      const token = await StandardTokenMock.new(vaultSig.address, 1000);
      const request = token.transfer.request(accounts[0], 100);
      const rsv = await sign(accounts[1]);

      const tx = await vaultSig.execute([ rsv.r ], [ rsv.s ], [ rsv.v ],
        token.address, 0, request.params[0].data);
      assert.equal(tx.receipt.status, '0x01', 'status');
      assert.equal(tx.logs.length, 1, 'logs');
      assert.equal(tx.logs[0].event, 'Execution');
      assert.equal(tx.logs[0].args.to, token.address, 'to');
      assert.equal(tx.logs[0].args.value, 0, 'value');
      assert.equal(tx.logs[0].args.data, request.params[0].data, 'data');
 
      const balance = await token.balanceOf(vaultSig.address);
      assert.equal(balance, 900, 'balance multisig');
      const balance0 = await token.balanceOf(accounts[0]);
      assert.equal(balance0, 100, 'balance account 0');
    });

    it('should not execute both ETH and ERC20 transfer', async function () {
      const token = await StandardTokenMock.new(vaultSig.address, 1000);
      const request = token.transfer.request(accounts[0], 100);
      const rsv = await sign(accounts[1]);

      await assertRevert(vaultSig.execute([ rsv.r ], [ rsv.s ], [ rsv.v ],
        token.address, 1, request.params[0].data));
    });
  });
});
