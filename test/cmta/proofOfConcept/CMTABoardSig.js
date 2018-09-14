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
const CMTAShareholderAgreement =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareholderAgreement.sol');

contract('BoardSig', function (accounts) {
  let token;
  let boardSig, agreement, request;

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

  describe('with three address and threshold of 2', function () {
    beforeEach(async function () {
      token = await CMTAPocToken.new("Test", "TST", "MtPelerin", "0ABCDEFG", "http://mtpelerin.com/", 100);
      boardSig = await CMTABoardSig.new([ accounts[1], accounts[2], accounts[3] ], 2);
      agreement = await CMTAShareholderAgreement.new("0x0122445666777");
      await token.issue(1000000);
      await token.transfer(agreement.address, 1000000);
      await token.transferOwnership(agreement.address);
    });

    it('should not issueShares without an agreement', async function () {
      const rsv1 = await sign(accounts[1]);
      const tx = await assertRevert(boardSig.issueShares(
        0,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    it('should not issueShares with someone else agreement', async function () {
      const rsv1 = await sign(accounts[1]);
      const tx = await assertRevert(boardSig.issueShares(
        agreement.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    it('should not issueShares without a token defined', async function () {
      await agreement.transferOwnership(boardSig.address);
      const rsv1 = await sign(accounts[1]);
      const tx = await assertRevert(boardSig.issueShares(
        agreement.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });

    describe('with an agreeement configured', function () {
      beforeEach(async function () {
        await agreement.configureToken(token.address);
        await agreement.transferOwnership(boardSig.address);
      });
    
      it('should not issueShares with 1 signatures', async function () {
        const rsv1 = await sign(accounts[1]);
        const tx = await assertRevert(boardSig.issueShares(
          agreement.address,
          [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
        ));
      });
 
      it('should issueShares with 2 signatures', async function () {
        const rsv1 = await sign(accounts[1]);
        const rsv2 = await sign(accounts[2]);
        const tx = await boardSig.issueShares(
          agreement.address,
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
        );
      });
    });
  });
});
