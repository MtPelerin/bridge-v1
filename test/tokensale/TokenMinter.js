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

const assertRevert = require('../helpers/assertRevert');
const MintableTokenMock = artifacts.require('MintableBridgeTokenMock.sol');
const TokenMinter = artifacts.require('TokenMinter.sol');
const MPLSaleConfig = artifacts.require('MPLSaleConfig.sol');

contract('TokenMinter', function (accounts) {
  let minter, token, saleConfig;

  beforeEach(async function () {
    saleConfig = await MPLSaleConfig.new();
    minter = await TokenMinter.new(saleConfig.address, accounts[0]);
    token = await MintableTokenMock.new('Test', 'TST');
  });

  it('should have no token', async function () {
    const tokenAddr = await minter.token();
    assert.equal(
      tokenAddr,
      '0x0000000000000000000000000000000000000000',
      'no token'
    );
  });

  it('should not setup a token when minter is not owner', async function () {
    await assertRevert(minter.setupToken(token.address, accounts[4], accounts[1], accounts[2]));
  });

  it('should setup a token when minter is owner', async function () {
    await token.transferOwnership(minter.address);
    const tx = await minter.setupToken(token.address, accounts[4], accounts[1], accounts[2]);
    assert.equal(tx.receipt.status, '0x1', 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'Mint');
    assert.equal(tx.logs[0].args.to, accounts[1], 'lot2 supply');
    const lot2Supply = await saleConfig.tokensaleLot2Supply();
    assert.equal(
      tx.logs[0].args.amount.toNumber(),
      lot2Supply.toNumber(),
      'lot2 supply amount'
    );
    assert.equal(tx.logs[1].event, 'Mint');
    assert.equal(tx.logs[1].args.to, accounts[2], 'reserved supply');
    const reservedSupply = await saleConfig.reservedSupply();
    assert.equal(
      tx.logs[1].args.amount.toNumber(),
      reservedSupply.toNumber(),
      'reserved supply amount'
    );
    const tokenAddr = await minter.token();
    assert.equal(tokenAddr, token.address, 'token');
    const balanceLot2 = await token.balanceOf(accounts[1]);
    assert.equal(balanceLot2.toNumber(), lot2Supply.toNumber(), 'balance lot2');
    const balanceReserved = await token.balanceOf(accounts[2]);
    assert.equal(balanceReserved.toNumber(), reservedSupply.toNumber(), 'balance reserved');
  });

  it('should not setup a token pre minted', async function () {
    await token.mint(100, accounts[1]);
    await token.transferOwnership(minter.address);
    await assertRevert(
      minter.setupToken(token.address, accounts[4], accounts[1], accounts[2])
    );
  });

  it('should not setup a token as not owner', async function () {
    await token.transferOwnership(minter.address);
    await assertRevert(
      minter.setupToken(
        token.address,
        accounts[0],
        accounts[1],
        accounts[2],
        { from: accounts[1] }
      )
    );
  });

  it('should not setup a token that have finish minting', async function () {
    await token.finishMinting();
    await assertRevert(
      minter.setupToken(token.address, accounts[4], accounts[1], accounts[2])
    );
  });

  it('should prevent setup token when minting lot2/reserve fails', async function () {
    await token.enableMinting(false);
    await assertRevert(
      minter.setupToken(token.address, accounts[4], accounts[1], accounts[2])
    );
  });

  describe('with a token setup', function () {
    beforeEach(async function () {
      await token.transferOwnership(minter.address);
      await minter.setupToken(token.address, accounts[4], accounts[1], accounts[2]);
    });

    it('should not have minting finished', async function () {
      const finished = await minter.mintingFinished();
      assert.ok(!finished, 'finished');
    });

    it('should finish minting', async function () {
      const tx = await minter.finishMinting();
      assert.equal(tx.receipt.status, '0x1', 'status');
    });

    it('should mint below the config token supply', async function () {
      const tx = await minter.mint(accounts[3], 1000);
      assert.equal(tx.receipt.status, '0x1', 'status');
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Mint');
      assert.equal(tx.logs[0].args.to, accounts[3], 'to');
      assert.equal(
        tx.logs[0].args.amount.toNumber(),
        1000,
        'amount'
      );

      const balance = await token.balanceOf(accounts[3]);
      assert.equal(balance, 1000, 'balance');
    });

    it('should not mint 0 supply', async function () {
      await assertRevert(minter.mint(accounts[1], 0));
    });

    it('should not mint above the config token supply', async function () {
      const tokenSupply = await saleConfig.tokenSupply();
      await assertRevert(minter.mint(accounts[1], tokenSupply));
    });

    it('should not release token', async function () {
      await assertRevert(minter.releaseToken());
      const balance = await token.balanceOf(accounts[4]);
      assert.equal(balance.toNumber(), 0, 'balance');
    });

    describe('and minting finished with no remaining', function () {
      beforeEach(async function () {
        const totalSupply = await token.totalSupply();
        const expectedSupply = await saleConfig.tokenSupply();
        await minter.mint(accounts[0], expectedSupply.sub(totalSupply));
        await minter.finishMinting();
      });

      it('should release token', async function () {
        const tx = await minter.releaseToken();
        assert.equal(tx.receipt.status, '0x1', 'status');
        assert.equal(tx.logs.length, 2);
        assert.equal(tx.logs[0].event, 'MintFinished');
        assert.equal(tx.logs[1].event, 'OwnershipTransferred');
        assert.equal(
          tx.logs[1].args.previousOwner,
          minter.address,
          'previousOwner'
        );
        assert.equal(
          tx.logs[1].args.newOwner,
          accounts[0],
          'newOwner'
        );

        const balance = await token.balanceOf(accounts[4]);
        assert.equal(balance.toNumber(), 0, 'balance');
      });
    });

    describe('and minting finished with some remaining', function () {
      beforeEach(async function () {
        await minter.finishMinting();
      });

      it('should have minting finished', async function () {
        const finished = await minter.mintingFinished();
        assert.ok(finished, 'finished');
      });

      it('should not mint anymore', async function () {
        await assertRevert(minter.mint(1, accounts[1]));
      });

      it('should release the token', async function () {
        const tx = await minter.releaseToken();
        assert.equal(tx.receipt.status, '0x1', 'status');
        assert.equal(tx.logs.length, 3);
        assert.equal(tx.logs[0].event, 'Mint');
        assert.equal(tx.logs[0].args.to, accounts[4], 'to');

        const lot1Supply = await saleConfig.tokensaleLot1Supply();
        assert.equal(
          tx.logs[0].args.amount.toNumber(),
          lot1Supply.toNumber(),
          'mint lot1 supply'
        );
        assert.equal(tx.logs[1].event, 'MintFinished');
        assert.equal(tx.logs[2].event, 'OwnershipTransferred');
        assert.equal(
          tx.logs[2].args.previousOwner,
          minter.address,
          'previousOwner'
        );
        assert.equal(
          tx.logs[2].args.newOwner,
          accounts[0],
          'newOwner'
        );

        const balance = await token.balanceOf(accounts[4]);
        assert.equal(balance.toNumber(), lot1Supply.toNumber(), 'balance');
      });

      it('should prevent release if mint remaining lot1 fails', async function () {
        await token.enableMinting(false);
        await assertRevert(minter.releaseToken());
      });
    });
  });
});
