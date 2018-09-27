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
const TokenWithClaims = artifacts.require('../contracts/token/TokenWithClaimsMock');
const EmptyClaimable = artifacts.require('../contracts/claimable/EmptyClaimable');

contract('TokenWithClaims', function (accounts) {
  let token;

  describe('with no claims', function () {
    beforeEach(async function () {
      token = await TokenWithClaims.new([], accounts[0], 10000);
    });

    it('should have a length', async function () {
      const length = await token.claimableLength();
      assert.equal(length, 0, 'length');
    });

    it('should not find any claims', async function () {
      const hasClaims = await token.hasClaims(accounts[1]);
      assert.ok(!hasClaims, 'hasClaims');
    });

    it('should allow owner to add a claimable', async function () {
      const claimable1 = await EmptyClaimable.new(true);
      const tx = await token.addClaimable(claimable1.address);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      const length = await token.claimableLength();
      assert.equal(length.toNumber(), 1, 'length');
    });

    it('should prevent non owner to add a claimable', async function () {
      const claimable1 = await EmptyClaimable.new(true);
      await assertRevert(token.addClaimable(claimable1.address, { from: accounts[1] }));
    });

    it('should revert when adding claimable address 0', async function () {
      await assertRevert(token.addClaimable(0x0));
    });

    it('should allow owner to add many claimables', async function () {
      const claimable1 = await EmptyClaimable.new(true);
      const claimable2 = await EmptyClaimable.new(false);

      const tx = await token.addManyClaimables([ claimable1.address, claimable2.address ]);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      const length = await token.claimableLength();
      assert.equal(length.toNumber(), 2, 'length');
    });

    it('should prevent non owner to add many claimables', async function () {
      const claimable1 = await EmptyClaimable.new(true);
      const claimable2 = await EmptyClaimable.new(false);

      await assertRevert(token.addManyClaimables([ claimable1.address, claimable2.address ], { from: accounts[1] }));
    });

    it('should revert when adding no claimables', async function () {
      await assertRevert(token.addManyClaimables([ ]));
    });

    it('should revert when removing a claimable', async function () {
      await assertRevert(token.removeClaimable(0));
    });

    it('should create no proofs during transfer', async function () {
      const tx = await token.transfer(accounts[1], 100);
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 1, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
    });

    it('should create no proofs during transferFrom', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFrom(accounts[0], accounts[1], 100, { from: accounts[2] });
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 1, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
    });

    it('should transferWithProofs when called with no proofs from', async function () {
      const tx = await token.transferWithProofs(accounts[1], 100, false, true);
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 2, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId1');
    });

    it('should transferWithProofs when called with proofs from and to', async function () {
      const tx = await token.transferWithProofs(accounts[1], 100, true, false);
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 2, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId0');
    });

    it('should transferWithProofs when called with no proofs both from and to', async function () {
      const tx = await token.transferWithProofs(accounts[1], 100, false, false);
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 1, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
    });

    it('should transferWithProofs when called with proofs both from and to', async function () {
      const tx = await token.transferWithProofs(accounts[1], 100, true, true);
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 3, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId0');
      assert.equal(tx.logs[2].event, 'ProofOfOwnership');
      assert.equal(tx.logs[2].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[2].args.proofId.toNumber(), 0, 'proofId1');
    });

    it('should transferFromWithProofs when called with no proofs from', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFromWithProofs(accounts[0], accounts[1], 100, false, true, { from: accounts[2] });
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 2, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId1');
    });

    it('should transferFromWithProofs when called with no proofs to', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFromWithProofs(accounts[0], accounts[1], 100, true, false, { from: accounts[2] });
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 2, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId0');
    });

    it('should transferFromWithProofs when called with no proofs both from and to', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFromWithProofs(accounts[0], accounts[1], 100, false, false, { from: accounts[2] });
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 1, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
    });

    it('should transferFromWithProofs when called with proofs both from and to', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFromWithProofs(accounts[0], accounts[1], 100, true, true, { from: accounts[2] });
      assert.equal((await token.balanceOf(accounts[1])).toNumber(), 100, 'balance accounts[1]');
      assert.equal(tx.logs.length, 3, 'logs.length');
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 0, 'proofId0');
      assert.equal(tx.logs[2].event, 'ProofOfOwnership');
      assert.equal(tx.logs[2].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[2].args.proofId.toNumber(), 0, 'proofId1');
    });
  });

  describe('with an EmptyClaimable active', function () {
    let claimable1;

    beforeEach(async function () {
      claimable1 = await EmptyClaimable.new(true);
      token = await TokenWithClaims.new([claimable1.address], accounts[0], 10000);
    });

    it('should hasClaims', async function () {
      const hasClaims = await token.hasClaims(accounts[1]);
      assert.ok(hasClaims, 'hasClaims');
    });

    it('should have one claimable', async function () {
      const length = await token.claimableLength();
      assert.equal(length.toNumber(), 1, 'one claimable');
    });

    it('should have the EmptyClaimable with claimableId 1', async function () {
      const claimableAddress = await token.claimable(0);
      assert.equal(claimableAddress, claimable1.address, 'claimable address');
    });

    it('should only accept a new claimable from its creator', async function () {
      const claimable2 = await EmptyClaimable.new(true);
      await assertRevert(token.addClaimable(claimable2.address, { from: accounts[1] }));
    });

    it('should only remove a claimable from its creator', async function () {
      await assertRevert(token.removeClaimable(0, { from: accounts[1] }));
    });

    it('should log when adding a claimable', async function () {
      const claimable2 = await EmptyClaimable.new(true);
      const addReceipt = await token.addClaimable(claimable2.address);
      const length = await token.claimableLength();
      assert.equal(length.toNumber(), 2, 'one claimable');
      assert.equal(addReceipt.logs.length, 1);
      assert.equal(addReceipt.logs[0].event, 'ClaimableAdded');
      assert.equal(addReceipt.logs[0].args.claimableId, 1);
    });

    it('should log when removing a claimable', async function () {
      const removeReceipt = await token.removeClaimable(0);
      const length = await token.claimableLength();
      assert.equal(length.toNumber(), 0, 'one claimable');
      assert.equal(removeReceipt.logs.length, 1);
      assert.equal(removeReceipt.logs[0].event, 'ClaimableRemoved');
      assert.equal(removeReceipt.logs[0].args.claimableId, 0);
    });

    it('should create a proof of ownership during transfer', async function () {
      const tx = await token.transfer(accounts[1], 100);
      assert.equal(tx.logs.length, 3);
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId, 0, 'proofId0');
      assert.equal(tx.logs[2].event, 'ProofOfOwnership');
      assert.equal(tx.logs[2].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[2].args.proofId, 0, 'proofId1');
    });

    it('should create a proof of ownership during transferFrom', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFrom(
        accounts[0], accounts[1], 100, { from: accounts[2] }
      );
      assert.equal(tx.logs.length, 3);
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId, 0, 'proofId0');
    });
  });

  describe('with an EmptyClaimable inactive', function () {
    let claimable1;

    beforeEach(async function () {
      claimable1 = await EmptyClaimable.new(false);
      token = await TokenWithClaims.new([claimable1.address], accounts[0], 10000);
      assert.equal((await token.claimableLength()).toNumber(), 1, 'one claimable');
      assert.equal(await token.claimable(0), claimable1.address, 'claimable1');
    });

    it('should not find any claims', async function () {
      const hasClaims = await token.hasClaims(accounts[1]);
      assert.ok(!hasClaims, 'no claims');
    });

    it('should not have claims when removing the claimable', async function () {
      await token.removeClaimable(0);
      assert.equal((await token.claimableLength()).toNumber(), 0, 'No claimables');
      const hasClaims = await token.hasClaims(accounts[1]);
      assert.ok(!hasClaims, 'no claims');
    });

    it('should not create any proof of ownership during transfer', async function () {
      const tx = await token.transfer(accounts[1], 100);
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Transfer');
    });

    it('should not create any proof of ownership during transferFrom', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFrom(
        accounts[0], accounts[1], 100, { from: accounts[2] }
      );
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Transfer');
    });
  });

  describe('with 2 EmptyClaim actives and 1 EmptyClaim inactive', function () {
    let claimable1;
    let claimable2;
    let claimable3;

    beforeEach(async function () {
      claimable1 = await EmptyClaimable.new(true);
      claimable2 = await EmptyClaimable.new(true);
      claimable3 = await EmptyClaimable.new(false);
      token = await TokenWithClaims.new(
        [claimable1.address, claimable2.address, claimable3.address], accounts[0], 10000
      );
      assert.equal((await token.claimableLength()).toNumber(), 3, 'two claimables');
      assert.equal(await token.claimable(0), claimable1.address, 'claimable1');
      assert.equal(await token.claimable(1), claimable2.address, 'claimable2');
      assert.equal(await token.claimable(2), claimable3.address, 'claimable3');
      await token.transfer(accounts[1], 100);
    });

    it('should have only one proof of ownership per participants during transfer', async function () {
      const tx = await token.transfer(accounts[1], 100);
      assert.equal(tx.logs.length, 3);
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 1, 'proofId0');
      assert.equal(tx.logs[2].event, 'ProofOfOwnership');
      assert.equal(tx.logs[2].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[2].args.proofId.toNumber(), 1, 'proofId1');
    });

    it('should have only one proof of ownership per participants during transferFrom', async function () {
      await token.approve(accounts[2], 100);
      const tx = await token.transferFrom(
        accounts[0], accounts[1], 100, { from: accounts[2] }
      );
      assert.equal(tx.logs.length, 3);
      assert.equal(tx.logs[0].event, 'Transfer');
      assert.equal(tx.logs[1].event, 'ProofOfOwnership');
      assert.equal(tx.logs[1].args.holder, accounts[0], 'holder0');
      assert.equal(tx.logs[1].args.proofId.toNumber(), 1, 'proofId0');
      assert.equal(tx.logs[2].event, 'ProofOfOwnership');
      assert.equal(tx.logs[2].args.holder, accounts[1], 'holder1');
      assert.equal(tx.logs[2].args.proofId.toNumber(), 1, 'proofId1');
    });

    it('should have 0 ownership when two active claimables are removed', async function () {
      await token.removeClaimable(0);
      await token.removeClaimable(1);
      
      const tx = await token.transfer(accounts[1], 100);
      assert.equal(tx.logs.length, 1);
      assert.equal(tx.logs[0].event, 'Transfer');
    });
  });
});
