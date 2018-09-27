'participant strict';

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

const abi = require('ethjs-abi');
const assertJump = require('../../helpers/assertJump');
const assertRevert = require('../../helpers/assertRevert');
const SecretMultiSig = artifacts.require('../../contracts/multisig/public/SecretMultiSig.sol');

contract('SecretMultiSig', function (accounts) {
  let multiSig, request;

  beforeEach(async function () {
    multiSig = await SecretMultiSig.new(100, 3600 * 24, [ accounts[0] ], [ 100 ]);
    request = multiSig.updateConfiguration.request(50, 3600 * 24 * 7);
  });

  async function suggest () {
    const txReceipt = await multiSig.suggest(request.params[0].to, 0, request.params[0].data);
    assert.equal(txReceipt.logs.length, 1);
    assert.equal(txReceipt.logs[0].event, 'TransactionAdded');
    const txId = (txReceipt.logs[0].args.transactionId).toNumber();
    assert.equal((await multiSig.transactionCount()).toNumber(), txId + 1, 'transactionCount');
    assert.equal(await multiSig.isConfirmed(txId), false, 'isConfirmed');
    assert.equal(await multiSig.hasParticipated(txId, accounts[0]), false, 'hasParticipated');
    assert.equal(await multiSig.isLocked(txId), false, 'isLocked');
    assert.equal(await multiSig.isExpired(txId), false, 'isExpired');
    assert.equal(await multiSig.isCancelled(txId), false, 'isCancelled');
    assert.equal(await multiSig.transactionCreator(txId), accounts[0], 'transactionCreator');
    assert.ok((await multiSig.transactionCreatedAt(txId)) < (new Date().getTime()) / 1000, 'transactionCreatedAt');
    assert.equal(await multiSig.isExecuted(txId), false, 'isExecuted');
    return txId;
  };

  function buildHash (txId) {
    const encodedParams = abi.encodeParams(
      [ 'uint256', 'uint256', 'address', 'uint256', 'bytes' ],
      [ web3.toHex(txId),
        web3.toHex(123456),
        request.params[0].to,
        web3.toHex(0),
        request.params[0].data,
      ]
    );
    return web3.sha3(encodedParams, { encoding: 'hex' });
  }

  async function suggestHash () {
    const txId = (await multiSig.transactionCount()).toNumber();
    const txReceipt = await multiSig.suggestHash(buildHash(txId));
    assert.equal(txReceipt.logs.length, 1);
    assert.equal(txReceipt.logs[0].event, 'TransactionAdded');
    assert.equal((await multiSig.transactionCount()).toNumber(), txId + 1, 'transactionCount');
    assert.equal(await multiSig.isExecuted(txId), false, 'isExecuted');
    return txId + 1;
  };

  async function approveToConfirm (txId) {
    const confirmationReceipt = await multiSig.approve(txId);
    assert.equal(confirmationReceipt.logs.length, 1);
    assert.equal(confirmationReceipt.logs[0].event, 'TransactionConfirmed');
    assert.equal(confirmationReceipt.logs[0].args.transactionId, txId);
    assert.equal(await multiSig.isConfirmed(txId), true, 'isConfirmed');
    assert.equal(await multiSig.hasParticipated(txId, accounts[0]), true, 'hasParticipated');
    assert.equal(await multiSig.isExecuted(txId), false, 'isExecuted');
  }

  async function execute (txId) {
    const executionReceipt = await multiSig.execute(txId);
    assert.equal(executionReceipt.logs.length, 2);
    assert.equal(executionReceipt.logs[0].event, 'ConfigurationUpdated');
    assert.equal(executionReceipt.logs[0].args.threshold, 50);
    assert.equal(executionReceipt.logs[0].args.duration.toNumber(), 3600 * 24 * 7);
    assert.equal(executionReceipt.logs[1].event, 'Execution');
    assert.equal(executionReceipt.logs[1].args.transactionId, 0);
    assert.equal(await multiSig.threshold(), 50, 'Threshold');
    assert.equal((await multiSig.duration()).toNumber(), 3600 * 24 * 7, 'Duration');
    assert.equal(await multiSig.isExecuted(txId), true, 'isExecuted');
  }

  async function executeHash (txId) {
    const executionReceipt = await multiSig.executeHash(txId, 123456, request.params[0].to, 0, request.params[0].data);
    assert.equal(executionReceipt.logs.length, 3);
    assert.equal(executionReceipt.logs[0].event, 'TransactionRevealed');
    assert.equal(executionReceipt.logs[0].args.transactionId, 0);
    assert.equal(executionReceipt.logs[1].event, 'ConfigurationUpdated');
    assert.equal(executionReceipt.logs[1].args.threshold, 50);
    assert.equal(executionReceipt.logs[1].args.duration.toNumber(), 3600 * 24 * 7);
    assert.equal(executionReceipt.logs[2].event, 'Execution');
    assert.equal(executionReceipt.logs[2].args.transactionId, 0);
    assert.equal(await multiSig.threshold(), 50, 'Threshold');
    assert.equal((await multiSig.duration()).toNumber(), 3600 * 24 * 7, 'Duration');
    assert.equal(await multiSig.isExecuted(txId), true, 'isExecuted');
  }

  describe('after initialization', function () {
    it('should not return isRevealed on non existing transaction', async function () {
      try {
        await multiSig.isRevealed(0);
        assert.fail('should have thrown before');
      } catch (error) {
        assertJump(error);
      }
    });

    it('should not reveal hash on non existing transaction', async function () {
      try {
        await multiSig.revealHash(0, 0, accounts[1], 0, '');
        assert.fail('should have thrown before');
      } catch (error) {
        assertJump(error);
      }
    });

    it('should validate buildHash', async function () {
      const expectedHash = buildHash(0);
      const foundHash = await multiSig.buildHash(
        0, 123456, request.params[0].to, 0, request.params[0].data);
      assert.equal(foundHash, expectedHash, 'hash');
    });

    it('should allow to suggestHash', async function () {
      const tx = await multiSig.suggestHash(web3.toHex(10));
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should not allow suggestHash with no hash', async function () {
      await assertRevert(multiSig.suggestHash(''));
    });

    it('should not execute non existing hash', async function () {
      try {
        await multiSig.executeHash(0, 0, accounts[1], 0, '');
        assert.fail('should have thrown before');
      } catch (error) {
        assertJump(error);
      }
    });
  });

  describe('with a default participant and a transaction (UpdateConfiguration) suggested', function () {
    beforeEach(async function () {
      await suggest();
    });

    it('should have one transaction', async function () {
      assert.equal((await multiSig.transactionCount()).toNumber(), 1, 'transactionCount');
    });

    it('should be not executable', async function () {
      const executable = await multiSig.isExecutable(0);
      assert.ok(!executable, 'executable');
    });

    it('should update default threshold and duration', async function () {
      await approveToConfirm(0);
      await execute(0);
    });
  });

  describe('with a default participant and a transaction (UpdateConfiguration) hash suggested', function () {
    beforeEach(async function () {
      await suggestHash();
    });
  
    it('should have one transaction', async function () {
      assert.equal((await multiSig.transactionCount()).toNumber(), 1, 'transactionCount');
    });

    it('should reveal transaction', async function () {
      const tx = await multiSig.revealHash(0, 123456, request.params[0].to, 0, request.params[0].data);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'TransactionRevealed');
      assert.equal(tx.logs[0].args.transactionId, 0);
    });

    it('should reveal transaction if hash does not match', async function () {
      await assertRevert(
        multiSig.revealHash(0, 1, request.params[0].to, 0, request.params[0].data));
    });

    it('should be not executable', async function () {
      const executable = await multiSig.isExecutable(0);
      assert.ok(!executable, 'executable');
    });

    it('should update default threshold and duration', async function () {
      await approveToConfirm(0);
      await executeHash(0);
    });
      
    it('should have a transaction destination defined', async function () {
      const destination = await multiSig.transactionDestination(0);
      assert.equal(destination, '0x0000000000000000000000000000000000000000', 'destination');
    });

    it('should have a transaction value defined', async function () {
      const value = await multiSig.transactionValue(0);
      assert.equal(value, 0, 'value');
    });

    it('should have a transaction data defined', async function () {
      const data = await multiSig.transactionData(0);
      assert.equal(data, '0x', 'data');
    });

    describe('and once revealed and approved', function () {
      beforeEach(async function () {
        await multiSig.revealHash(0, 123456, request.params[0].to, 0, request.params[0].data);
        await approveToConfirm(0);
      });

      it('should be revealed', async function () {
        const revealed = await multiSig.isRevealed(0);
        assert.ok(revealed, 'revealed');
      });

      it('should be executable', async function () {
        const executable = await multiSig.isExecutable(0);
        assert.ok(executable, 'executable');
      });

      it('should not reveal twice', async function () {
        await assertRevert(
          multiSig.revealHash(0, 123456, request.params[0].to, 0, request.params[0].data));
      });

      it('should have a transaction destination defined', async function () {
        const destination = await multiSig.transactionDestination(0);
        assert.equal(destination, request.params[0].to, 'destination');
      });

      it('should have a transaction value defined', async function () {
        const value = await multiSig.transactionValue(0);
        assert.equal(value, 0, 'value');
      });

      it('should have a transaction data defined', async function () {
        const data = await multiSig.transactionData(0);
        assert.equal(data, request.params[0].data, 'data');
      });

      it('should let participant execute', async function () {
        execute(0);
      });

      it('should not let participant executeHash', async function () {
        await assertRevert(
          multiSig.executeHash(0, 123456, request.params[0].to, 0, request.params[0].data));
      });
    });
  });
});
