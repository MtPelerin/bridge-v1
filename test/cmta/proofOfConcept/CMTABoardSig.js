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
const signer = require('../../helpers/signer');

const CMTAPocToken = artifacts.require('../contracts/cmta/proofOfConcept/CMTAPocToken.sol');
const CMTABoardSig = artifacts.require('../contracts/cmta/proofOfConcept/CMTABoardSig.sol');
const CMTAShareDistribution =
  artifacts.require('../contracts/cmta/proofOfConcept/CMTAShareDistribution.sol');

contract('BoardSig', function (accounts) {
  const TOKENIZE_CODE_TO_SIGN = web3.sha3('TOKENIZE');
  const ALLOCATE_CODE_TO_SIGN = web3.sha3('ALLOCATE');
  const hash = '0x679c6dccb057a2b3f9682835fc5bfc3a0296345c376fe7d716ba42fddeed803a';
  const nextYear = Math.floor((new Date()).getTime() / 1000) + 3600 * 24 * 365;

  let token, shareDistribution, boardSig;

  it('should create the BoardSig', async function () {
    boardSig = await CMTABoardSig.new([ accounts[1], accounts[2], accounts[3] ], 2);
    signer.multiSig = boardSig;
  });

  describe('with three addresses and threshold of 2', function () {
    let tokenizeToSign;

    beforeEach(async function () {
      boardSig = await CMTABoardSig.new([ accounts[1], accounts[2], accounts[3] ], 2);
      signer.multiSig = boardSig;
      token = await CMTAPocToken.new('Test', 'TST', 1000000, 'Swissquote SA', '0ABCDEFG', 'https://ge.ch/', 100, hash);
      shareDistribution = await CMTAShareDistribution.new(
        hash,
        0
      );
      tokenizeToSign = await boardSig.tokenizeHash(shareDistribution.address);
      await shareDistribution.configureToken(token.address, hash);
      await token.transfer(shareDistribution.address, 1000000);
      await token.validateKYCUntil(shareDistribution.address, nextYear);
    });

    it('should provide code to sign', async function () {
      const tokenizeToSignFound = await boardSig.TOKENIZE();
      assert.equal(tokenizeToSignFound, TOKENIZE_CODE_TO_SIGN, 'TOKENIZE code');
    });

    it('should provide tokenize hash', async function () {
      const tokenizeToSignFound = await boardSig.tokenizeHash(shareDistribution.address);
      let tokenizeToSignExpected = web3.sha3(
        signer.encodeParams(
          ['bytes32', 'address'],
          [ TOKENIZE_CODE_TO_SIGN, shareDistribution.address ]
        ), { encoding: 'hex' }
      );
      assert.equal(tokenizeToSignFound, tokenizeToSignExpected, 'data to sign');
    });

    it('should provide allocate hash', async function () {
      const tokenizeToSignFound = await boardSig.allocateHash(
        [ accounts[0], accounts[1] ], [ 9000, 5000 ], 1578000000000);
      let tokenizeToSignExpected = web3.sha3(
        signer.encodeParams(
          ['bytes32', 'address[]', 'uint256[]', 'uint256' ],
          [ ALLOCATE_CODE_TO_SIGN, [ accounts[0], accounts[1] ], [ 9000, 5000 ], 1578000000000 ]
        ), { encoding: 'hex' });
      assert.equal(tokenizeToSignFound, tokenizeToSignExpected, 'data to sign');
    });

    it('should not tokenize shares when token is not owned', async function () {
      await shareDistribution.transferOwnership(boardSig.address);
      const rsv1 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[1]);
      await assertRevert(boardSig.tokenizeShares(
        shareDistribution.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });
     
    it('should not tokenize shares when shareDistribution is not owned', async function () {
      await token.transferOwnership(boardSig.address);
      const rsv1 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[1]);
      await assertRevert(boardSig.tokenizeShares(
        shareDistribution.address,
        [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
      ));
    });
 
    describe('with a token defined and a share distribution configured', function () {
      beforeEach(async function () {
        await token.transferOwnership(boardSig.address);
        await shareDistribution.transferOwnership(boardSig.address);
      });
    
      it('should not tokenize shares with 1 signatures', async function () {
        const rsv1 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[1]);
        await assertRevert(boardSig.tokenizeShares(
          shareDistribution.address,
          [ rsv1.r ], [ rsv1.s ], [ rsv1.v ]
        ));
      });
 
      it('should tokenize shares with 2 signatures', async function () {
        const rsv1 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[1]);
        const rsv2 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[2]);

        const tx = await boardSig.tokenizeShares(
          shareDistribution.address,
          [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
        );
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 1);
        assert.equal(tx.logs[0].event, 'ShareTokenization');
        assert.equal(tx.logs[0].args.distribution, shareDistribution.address);
      });

      describe('when tokenized', function () {

        beforeEach(async function () {
          const rsv1 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[1]);
          const rsv2 = await signer.sign(boardSig.address, 0, tokenizeToSign, 0, accounts[2]);

          const tx = await boardSig.tokenizeShares(
            shareDistribution.address,
            [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
          );
        });

        it('should allocate and kyc many users', async function () {
          const allocateToSign = await boardSig.allocateHash(
            [ accounts[0], accounts[1] ], [ 1000, 8000 ], 1578000000000);

          const rsv1 = await signer.sign(boardSig.address, 0, allocateToSign, 0, accounts[1]);
          const rsv2 = await signer.sign(boardSig.address, 0, allocateToSign, 0, accounts[2]);

          const tx = await boardSig.allocateAndKYCMany(
            [ accounts[0], accounts[1] ], [ 1000, 8000 ], 1578000000000,
            [ rsv1.r, rsv2.r ], [ rsv1.s, rsv2.s ], [ rsv1.v, rsv2.v ]
          );
          assert.equal(parseInt(tx.receipt.status), 1, 'status');

          let totalAllocations = await shareDistribution.totalAllocations();
          assert.equal(totalAllocations, 9000, 'total allocations');

          let isAccount0KYC = await token.isKYCValid(accounts[0]);
          assert.ok(isAccount0KYC, 'account 0 kyc');

          let isAccount1KYC = await token.isKYCValid(accounts[1]);
          assert.ok(isAccount1KYC, 'account 1 kyc');

          let isAccount2KYC = await token.isKYCValid(accounts[2]);
          assert.ok(!isAccount2KYC, 'account not 2 kyc');
        });
      });
    });
  });
});
