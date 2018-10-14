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
const MPSSaleConfig = artifacts.require('MPSSaleConfig.sol');

contract('TokenMinter', function (accounts) {
  let minter, token, saleConfig;

  beforeEach(async function () {
    saleConfig = await MPSSaleConfig.new();
    minter = await TokenMinter.new(saleConfig.address, accounts[0], [ accounts[1], accounts[2] ]);
    token = await MintableTokenMock.new('Test', 'TST');
  });

  it('should have LotCreated events', async function () {
     const events = await new Promise((resolve, reject) => {
       const filter = web3.eth.filter({
         fromBlock: 0,
         toBlock: 'latest',
         address: minter.address,
         topics: []
       }).get((error, result) => {
         resolve(result);
       })
     });
     assert.equal(events.length, 2, '2 events');
     assert.equal(events[0].topics[0], web3.sha3('LotCreated(uint256,uint256)'), 'LotCreated');
     assert.equal(events[1].topics[0], web3.sha3('LotCreated(uint256,uint256)'), 'LotCreated');
  });

  it('should have a sale config', async function () {
    const saleConfigAddress = await minter.config();
    assert.equal(saleConfigAddress, saleConfig.address, 'sale config address');
  });

  it('should have lot mintable supply', async function () {
    const lotMintableSupply1 = await minter.lotMintableSupply(0);
    assert.equal(lotMintableSupply1.toNumber(), 500000, 'lot 1 mintable supply');
    const lotMintableSupply2 = await minter.lotMintableSupply(1);
    assert.equal(lotMintableSupply2.toNumber(), 9500000, 'lot 2 mintable supply');
  });

  it('should have lot vault', async function () {
    const vault1 = await minter.lotVault(0);
    assert.equal(vault1, accounts[1], 'vault 1');
    const vault2 = await minter.lotVault(1);
    assert.equal(vault2, accounts[2], 'vault 2');
  });

  it('should returns if address is an active minter', async function () {
    const activeMinter1 = await minter.isLotMinter(0, accounts[1]);
    assert.ok(!activeMinter1, 'inactive minter 1');
    const activeMinter2 = await minter.isLotMinter(1, accounts[1]);
    assert.ok(!activeMinter2, 'inactive minter 2');
    const activeMinter3 = await minter.isLotMinter(1, accounts[2]);
    assert.ok(!activeMinter3, 'inactive minter 3');
  });

  it('should have active minters in lot', async function () {
    const activeMinters1 = await minter.lotActiveMinters(0);
    assert.equal(activeMinters1.toNumber(), 0, '0 active minters');
    const activeMinters2 = await minter.lotActiveMinters(1);
    assert.equal(activeMinters2.toNumber(), 0, '2 active minters');
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
    await assertRevert(minter.setup(token.address, [ accounts[4], accounts[1] ]));
  });

  it('should not setup a token pre minted', async function () {
    await token.mint(accounts[1], 100);
    await token.transferOwnership(minter.address);
    await assertRevert(
      minter.setup(token.address, [ accounts[4], accounts[1] ])
    );
  });

  it('should not setup a token as not owner', async function () {
    await token.transferOwnership(minter.address);
    await assertRevert(
      minter.setup(
        token.address,
        [ accounts[4], accounts[1] ],
        { from: accounts[1] }
      )
    );
  });

  it('should not setup a token that have finish minting', async function () {
    await token.finishMinting();
    await assertRevert(
      minter.setup(token.address, [ accounts[4], accounts[1] ])
    );
  });

  it('should prevent setup token when minting lot2/reserve fails', async function () {
    await token.enableMinting(false);
    await assertRevert(
      minter.setup(token.address, [ accounts[4], accounts[1] ])
    );
  });

  it('should setup a token when minter is owner', async function () {
    await token.transferOwnership(minter.address);
    const tx = await minter.setup(token.address, [ accounts[4], accounts[1] ]);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 2);
    assert.equal(tx.logs[0].event, 'MinterAdded');
    assert.equal(tx.logs[0].args.lotId, 0, 'lot 1');
    assert.equal(tx.logs[0].args.minter, accounts[4], 'minter4');
    assert.equal(tx.logs[1].event, 'MinterAdded');
    assert.equal(tx.logs[1].args.lotId, 0, 'lot 1');
    assert.equal(tx.logs[1].args.minter, accounts[1], 'minter1');
    const tokenAddr = await minter.token();
    assert.equal(tokenAddr, token.address, 'token');
  });

  it('should setup a token with not all sales configured', async function () {
    await token.transferOwnership(minter.address);
    const tx = await minter.setup(token.address, [  accounts[4], 0 ]);
    assert.equal(parseInt(tx.receipt.status), 1, 'status');
    assert.equal(tx.logs.length, 1);
    assert.equal(tx.logs[0].event, 'MinterAdded');
    assert.equal(tx.logs[0].args.lotId, 0, 'lot 1');
    assert.equal(tx.logs[0].args.minter, accounts[4], 'minter4');
    const tokenAddr = await minter.token();
    assert.equal(tokenAddr, token.address, 'token');
  });

  describe('with a token setup an sales partially configured', function () {
    beforeEach(async function () {
      await token.transferOwnership(minter.address);
      await minter.setup(token.address,
        [ accounts[4], '0x0000000000000000000000000000000000000000' ]);
    });

    it('should have 1 active minters for lot 1', async function () {
      const activeMinters1 = await minter.lotActiveMinters(0);
      assert.equal(activeMinters1.toNumber(), 1, '1 active minters');
      const activeMinters2 = await minter.lotActiveMinters(1);
      assert.equal(activeMinters2.toNumber(), 0, '0 active minters');
    });

    it('should allow setup minter', async function () {
      const tx = await minter.setupMinter(accounts[1], 1);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      const activeLots = await minter.activeLots();
      assert.equal(activeLots.toNumber(), 2, 'activeLots');
    });

    it('should prevent non owner to setup minter', async function () {
      await assertRevert(minter.setupMinter(accounts[1], 1, { from: accounts[2] }));
    });
  });

  describe('with a token setup', function () {
    beforeEach(async function () {
      await token.transferOwnership(minter.address);
      await minter.setup(token.address, [ accounts[4], accounts[1] ]);
    });

    it('should have a token', async function () {
      const tokenAddress = await minter.token();
      assert.equal(tokenAddress, token.address, 'token address');
    });

    it('should have a total mintable supply', async function () {
      const totalMintableSupply = await minter.totalMintableSupply();
      assert.equal(totalMintableSupply.toNumber(), 10 ** 7, 'total mintable supply');
    });

    it('should have a final token owner', async function () {
      const finalTokenOwner = await minter.finalTokenOwner();
      assert.equal(finalTokenOwner, accounts[0], 'final owner');
    });

    it('should have 2 active lots', async function () {
      const activeLots = await minter.activeLots();
      assert.equal(activeLots.toNumber(), 2, 'activeLots');
    });

    it('should have lot defined for minters', async function () {
      const lotId4 = await minter.minterLotId(accounts[4]);
      assert.equal(lotId4.toNumber(), 0, 'lot id 4');
      const lotId1 = await minter.minterLotId(accounts[1]);
      assert.equal(lotId1.toNumber(), 0, 'lot id 1');
    });

    it('should returns if address is an active minter', async function () {
      const activeMinter1 = await minter.isLotMinter(0, accounts[1]);
      assert.ok(activeMinter1, 'active minter 1');
      const activeMinter2 = await minter.isLotMinter(1, accounts[1]);
      assert.ok(!activeMinter2, 'inactive minter 2');
      const activeMinter3 = await minter.isLotMinter(0, accounts[2]);
      assert.ok(!activeMinter3, 'inactive minter 3');
    });

    it('should have active minters in lot', async function () {
      const activeMinters1 = await minter.lotActiveMinters(0);
      assert.equal(activeMinters1.toNumber(), 2, '2 active minters');
      const activeMinters2 = await minter.lotActiveMinters(1);
      assert.equal(activeMinters2.toNumber(), 0, '0 active minters');
    });

    it('should not have minting finished', async function () {
      const finished = await minter.mintingFinished();
      assert.ok(!finished, 'finished');
    });

    it('should let account 1 finish minting', async function () {
      const tx = await minter.finishMinting({ from: accounts[1] });
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should let account 4 finish minting', async function () {
      const tx = await minter.finishMinting({ from: accounts[4] });
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should prevent account 2 from finish minting', async function () {
      await assertRevert(minter.finishMinting({ from: accounts[2] }));
    });

    it('should authorize owner to finish minting restricted sale1', async function () {
      const tx = await minter.finishMintingRestricted(accounts[1]);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should authorize owner to finish minting restricted sale2', async function () {
      const tx = await minter.finishMintingRestricted(accounts[4]);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
    });

    it('should prevent account2 to finish minting restricted sale1', async function () {
      await assertRevert(minter.finishMintingRestricted(accounts[1], { from: accounts[2] }));
    });

    it('should mint below the config token supply', async function () {
      const tx = await minter.mint(accounts[3], 1000, { from: accounts[4] });
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
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

    it('should mintRemainingLot for lot 2', async function () {
      const tx = await minter.mintRemainingLot(1);
      assert.equal(parseInt(tx.receipt.status), 1, 'status');
      assert.equal(tx.logs.length, 2);
      assert.equal(tx.logs[0].event, 'Mint');
      assert.equal(tx.logs[0].args.to, accounts[2], 'to');
      assert.equal(
        tx.logs[0].args.amount.toNumber(),
        9500000,
        'amount'
      );
      assert.equal(tx.logs[1].event, 'LotMinted');
      assert.equal(tx.logs[1].args.lotId.toNumber(), 1);
    });

    it('should not mint all remaining', async function () {
      await assertRevert(minter.mintAllRemaining());
    });

    it('should not mint 0 supply', async function () {
      await assertRevert(minter.mint(accounts[1], 0, { from: accounts[4] }));
    });

    it('should not mint above the config token supply', async function () {
      const tokenSupply = await saleConfig.tokenSupply();
      await assertRevert(minter.mint(accounts[1], tokenSupply, { from: accounts[4] }));
    });

    it('should not finish token minting', async function () {
      await assertRevert(minter.finishTokenMinting());
    });

    describe('and lot 1 partially minted and lot 2 finished with no remaining', function () {
      beforeEach(async function () {
        await minter.mintRemainingLot(1);
        await minter.finishMinting({ from: accounts[1] });
        await minter.mint(accounts[5], 1000, { from: accounts[4] });
      });

      it('should have total mintable supply', async function () {
        const totalMintableSupply = await minter.totalMintableSupply();
        assert.equal(totalMintableSupply.toNumber(), 499000, 'total mintable supply');
      });

      it('should have mintable supply lot 1', async function () {
        const mintableSupply = await minter.lotMintableSupply(0);
        assert.equal(mintableSupply.toNumber(), 499000, 'mintable supply lot 1');
      });

      it('should have 0 mintable supply lot 2', async function () {
        const mintableSupply = await minter.lotMintableSupply(1);
        assert.equal(mintableSupply.toNumber(), 0, 'mintable supply lot2');
      });

      it('should have one active minter in lot 1', async function () {
        const activeMinters = await minter.lotActiveMinters(0);
        assert.equal(activeMinters.toNumber(), 1, 'lot 1 active minter');
      });

      it('should have account 1 no more minter', async function () {
        const isMinter = await minter.isLotMinter(0, accounts[1]);
        assert.ok(!isMinter, 'account 1 no more minter');
      });

      it('should not mint all remaining', async function () {
        await assertRevert(minter.mintAllRemaining());
      });

      it('should not finish token minting', async function () {
        await assertRevert(minter.finishTokenMinting());
      });

      describe('and all minters finished', function () {
        beforeEach(async function () {
          await minter.finishMinting({ from: accounts[4] });
        });

        it('should mint remaining lot 1', async function () {
          const tx = await minter.mintRemainingLot(0);
          assert.equal(parseInt(tx.receipt.status), 1, 'status');
          assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, 'Mint');
          assert.equal(tx.logs[0].args.to, accounts[1], 'to');
          assert.equal(
            tx.logs[0].args.amount.toNumber(),
            499000,
            'amount'
          );
          assert.equal(tx.logs[1].event, 'LotMinted');
          assert.equal(tx.logs[1].args.lotId.toNumber(), 0, 'lot 1 minted');
        });

        it('should mint all remaining', async function () {
          const tx = await minter.mintAllRemaining();
          assert.equal(parseInt(tx.receipt.status), 1, 'status');
          assert.equal(tx.logs.length, 2);
          assert.equal(tx.logs[0].event, 'Mint');
          assert.equal(tx.logs[0].args.to, accounts[1], 'to');
          assert.equal(
            tx.logs[0].args.amount.toNumber(),
            499000,
            'amount'
          );
          assert.equal(tx.logs[1].event, 'LotMinted');
          assert.equal(tx.logs[1].args.lotId.toNumber(), 0, 'lot 1 minted');
        });
      });
    });

    describe('and all lot minted', function () {
      beforeEach(async function () {
        await minter.finishMinting({ from: accounts[1] });
        await minter.finishMinting({ from: accounts[4] });
        await minter.mintAllRemaining();
      });

      it('should finish token minting', async function () {
        const tx = await minter.finishTokenMinting();
        assert.equal(parseInt(tx.receipt.status), 1, 'status');
        assert.equal(tx.logs.length, 3);
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
        assert.equal(tx.logs[2].event, 'TokenReleased');
      });
    });
  });
});
