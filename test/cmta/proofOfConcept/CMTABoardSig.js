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

const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

contract('BoardSig', function (accounts) {
  const hash = '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a';
  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let token, shareDistribution, boardSig;

  let sign = async function (address) {
    const hash = await boardSig.replayProtection();
    const signedHash = web3.eth.sign(address, hash);

    return {
      r: '0x' + signedHash.slice(2).slice(0, 64),
      s: '0x' + signedHash.slice(2).slice(64, 128),
      v: web3.toDecimal(signedHash.slice(2).slice(128, 130)),
    };
  };

  it('should create the BoardSig', async function () {
    boardSig = await CMTABoardSig.new([ accounts[1], accounts[2], accounts[3] ], 2);
  });

  describe('with three addresses and threshold of 2', function () {
    beforeEach(async function () {
      token = await CMTAPocToken.new('Test', 'TST', 1000000, 'Swissquote SA', '0ABCDEFG', 'https://ge.ch/', 100, hash);
      boardSig = await CMTABoardSig.new([ accounts[1], accounts[2], accounts[3] ], 2);
    });

    it('should not tokenize shares without a token', async function () {
      const rsv1 = await sign(accounts[1]);
      await assertRevert(boardSig.tokenizeShares(
        0,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    it('should not tokenize shares with someone else token', async function () {
      const rsv1 = await sign(accounts[1]);
      await assertRevert(boardSig.tokenizeShares(
        token.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    it('should not issueShares with a token already used', async function () {
      await token.issue(1000000);
      await token.transferOwnership(boardSig.address);
      const rsv1 = await sign(accounts[1]);
      await assertRevert(boardSig.tokenizeShares(
        token.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    describe('with a token defined and a share distribution configured', function () {
      beforeEach(async function () {
        shareDistribution = await CMTAShareDistribution.new(
          hash,
          0
        );
        await shareDistribution.configureToken(token.address, hash);
        await token.transfer(shareDistribution.address, 1000000);
        await token.validateKYCUntil(shareDistribution.address, nextYear);
        await token.transferOwnership(boardSig.address);
        await shareDistribution.transferOwnership(boardSig.address);
      });
    
      it('should not issueShares with 1 signatures', async function () {
        const rsv1 = await sign(accounts[1]);
        await assertRevert(boardSig.tokenizeShares(
          token.address,
          [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
        ));
      });
 
      it('should issueShares with 2 signatures', async function () {
        const rsv1 = await sign(accounts[1]);
        const rsv2 = await sign(accounts[2]);
        const tx = await boardSig.tokenizeShares(
          shareDistribution.address,
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
        );
        assert.equal(tx.receipt.status, '0x01', 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'ShareTokenization');
        assert.equal(tx.logs[0].args.distribution, shareDistribution.address);
      });
    });
  });
});
