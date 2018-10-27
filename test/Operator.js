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
var OperatorMock = artifacts.require('../contracts/mock/OperatorMock.sol');

contract('Operator', function (accounts) {
  let operator;

  beforeEach(async function () {
    operator = await OperatorMock.new();
  });

  it('should have no operator', async function () {
    const operatorCount = await operator.operatorCount();
    assert.equal(operatorCount, 0, 'count');
  });

  it('should allow owner to set a new operator', async function () {
    const tx = await operator.defineOperators([ 'OPERATOR' ], [ accounts[2] ]);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'OperatorsCleared');
    assert.equal(tx.logs[0].args.size, 0);
    assert.equal(tx.logs[1].event, 'OperatorDefined');
    // eslint-disable-next-line no-control-regex
    assert.equal(web3.toAscii(tx.logs[1].args.name).replace(/\x00+$/, ''), 'OPERATOR');
    assert.equal(tx.logs[1].args._address, accounts[2]);
  });

  it('should allow owner to set new operators', async function () {
    const tx = await operator.defineOperators([ 'OPERATOR1', 'OPERATOR2' ], [ accounts[2], accounts[3] ]);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 3);
    assert.equal(tx.logs[0].event, 'OperatorsCleared');
    assert.equal(tx.logs[0].args.size, 0);
    assert.equal(tx.logs[1].event, 'OperatorDefined');
    // eslint-disable-next-line no-control-regex
    assert.equal(web3.toAscii(tx.logs[1].args.name).replace(/\x00+$/, ''), 'OPERATOR1');
    assert.equal(tx.logs[1].args._address, accounts[2]);
    assert.equal(tx.logs[2].event, 'OperatorDefined');
    // eslint-disable-next-line no-control-regex
    assert.equal(web3.toAscii(tx.logs[2].args.name).replace(/\x00+$/, ''), 'OPERATOR2');
    assert.equal(tx.logs[2].args._address, accounts[3]);
  });

  it('should not allow owner to set new operators with wrong operator/name count', async function () {
    await assertRevert(operator.defineOperators([ 'OPERATOR', 'OPERATOR2' ], [ accounts[2] ]));
  });

  it('should not allow non owner to set a new operator', async function () {
    await assertRevert(operator.defineOperators([ 'OPERATOR' ], [ accounts[2] ], { from: accounts[4] }));
  });

  describe('with authorities defined', function () {
    beforeEach(async function () {
      await operator.defineOperators([ 'LEGAL', 'REGULATOR' ], [ accounts[1], accounts[2] ]);
    });

    it('should have two operators', async function () {
      const count = await operator.operatorCount();
      assert.equal(count, 2, 'count');
    });

    it('should return accounts1 for operator1', async function () {
      const op1 = await operator.operatorAddress(0);
      assert.equal(op1, accounts[1], 'account 1');
    });

    it('should return accounts1 for operator2', async function () {
      const op2 = await operator.operatorAddress(1);
      assert.equal(op2, accounts[2], 'account 2');
    });

    it('should allow operator1 through onlyOperator modifier', async function () {
      await operator.testOnlyOperator({ from: accounts[1] });
    });

    it('should allow operator2 through onlyOperator modifier', async function () {
      await operator.testOnlyOperator({ from: accounts[2] });
    });

    it('should not allow non operator through onlyOperator modifier', async function () {
      await assertRevert(operator.testOnlyOperator());
    });

    it('should allow owner to set a new operator', async function () {
      const tx = await operator.defineOperators([ 'OPERATOR' ], [ accounts[2] ]);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 2);
      assert.equal(tx.logs[0].event, 'OperatorsCleared');
      assert.equal(tx.logs[0].args.size, 2);
      assert.equal(tx.logs[1].event, 'OperatorDefined');
      // eslint-disable-next-line no-control-regex
      assert.equal(web3.toAscii(tx.logs[1].args.name).replace(/\x00+$/, ''), 'OPERATOR');
      assert.equal(tx.logs[1].args._address, accounts[2]);
    });
  });
});
