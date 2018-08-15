'user strict';

const assertRevert = require('./helpers/assertRevert');

var UserRegistry = artifacts.require('../contracts/UserRegistry.sol');

contract('UserRegistry', function (accounts) {
  let userRegistry;
  const dayMinusOneTime = Math.floor((new Date()).getTime() / 1000) - 3600 * 24;
  const dayPlusOneTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 24;
  const dayPlusTwoTime = Math.floor((new Date()).getTime() / 1000) + 3600 * 48;
 
  describe('when empty', function () {
    beforeEach(async function () {
      userRegistry = await UserRegistry.new([], 0);
    });

    it('should have no users', async function () {
      const userCount = await userRegistry.userCount();
      assert.equal(userCount.toNumber(), 0, 'userCount');
    });

    it('should register a user', async function () {
      await userRegistry.registerUser(accounts[0], dayPlusOneTime);

      const userCount = await userRegistry.userCount();
      assert.equal(userCount.toNumber(), 1, 'userCount');
      
      const userId = await userRegistry.userId(accounts[0]);
      assert.equal(userId, 1, 'userId');

      const locked = await userRegistry.locked(1);
      assert.equal(locked, false, 'locked');

      const validUntilTime = await userRegistry.validUntilTime(1);
      assert.equal(validUntilTime, dayPlusOneTime, 'validUntilTime');
    });

    it('should register many users', async function () {
      await userRegistry.registerManyUsers([ accounts[0], accounts[1] ], dayPlusOneTime);

      const userCount = await userRegistry.userCount();
      assert.equal(userCount.toNumber(), 2, 'userCount');
      
      const userId1 = await userRegistry.userId(accounts[0]);
      assert.equal(userId1, 1, 'userId0');
      const userId2 = await userRegistry.userId(accounts[1]);
      assert.equal(userId2, 2, 'userId1');

      const locked1 = await userRegistry.locked(1);
      assert.equal(locked1, false, 'locked1');
      const locked2 = await userRegistry.locked(2);
      assert.equal(locked2, false, 'locked2');

      const validUntilTime1 = await userRegistry.validUntilTime(1);
      assert.equal(validUntilTime1, dayPlusOneTime, 'validUntilTime1');
      const validUntilTime2 = await userRegistry.validUntilTime(2);
      assert.equal(validUntilTime2, dayPlusOneTime, 'validUntilTime2');
    });

    it('should fails to check validUntil time for user 6', async function () {
      await assertRevert(userRegistry.validUntilTime(6));
    });

    it('should fails to check if user 6 is locked', async function () {
      await assertRevert(userRegistry.locked(6));
    });

    it('should fails at checking user 6 extended keys', async function () {
      await assertRevert(userRegistry.extended(6, 0));
    });

    it('should fails to check validity of user 6', async function () {
      await assertRevert(userRegistry.isValid(6));
    });

    it('should fail check address validity of accounts9', async function () {
      await assertRevert(userRegistry.isAddressValid(accounts[9]));
    });

    it('should not attach address to an non existing userId', async function () {
      await assertRevert(userRegistry.attachAddress(1, accounts[0]));
    });

    it('should not attach many addresses to non existing userId', async function () {
      await assertRevert(userRegistry.attachManyAddresses([ 1, 2 ], [ accounts[0], accounts[1] ]));
    });

    it('should not attach many addresses if different addresses length than ids', async function () {
      await assertRevert(userRegistry.attachManyAddresses([ 1, 2 ], [ accounts[0] ]));
    });

    it('should not lock a non existing user', async function () {
      await assertRevert(userRegistry.lockUser(1));
    });

    it('should not unlock a non existing user', async function () {
      await assertRevert(userRegistry.unlockUser(1));
    });

    it('should not lock many non existing users', async function () {
      await assertRevert(userRegistry.lockManyUsers([1, 2, 3]));
    });

    it('should not unlock many non existing users', async function () {
      await assertRevert(userRegistry.unlockManyUsers([1, 2, 3]));
    });

    it('should not update non existing user', async function () {
      await assertRevert(userRegistry.updateUser(1, dayPlusOneTime, false));
    });

    it('should not update non existing users', async function () {
      await assertRevert(userRegistry.updateManyUsers([ 1, 2, 3 ], dayPlusOneTime, false));
    });

    it('should not update non existing extended user', async function () {
      await assertRevert(userRegistry.updateUserExtended(1, 1, 100));
    });

    it('should not update non existing extended users', async function () {
      await assertRevert(userRegistry.updateManyUsersExtended([ 1, 2, 3 ], 1, 100));
    });
  });

  describe('with 4 accounts', function () {
    beforeEach(async function () {
      userRegistry = await UserRegistry.new([accounts[0], accounts[1], accounts[2], accounts[3]], dayPlusOneTime);
      await userRegistry.attachAddress(1, accounts[4]);
      await userRegistry.attachManyAddresses([ 2, 2 ], [accounts[5], accounts[6]]);
      await userRegistry.updateUser(3, dayMinusOneTime, false);
    });

    it('should have 4 users', async function () {
      const userCount = await userRegistry.userCount();
      assert.equal(userCount.toNumber(), 4, 'userCount');
    });

    it('should gives the same userId for account with multiple addresses', async function () {
      const userId = await userRegistry.userId(accounts[4]);
      assert.equal(userId, 1, 'userId');
    });

    it('should gives unlock for account1', async function () {
      const isLocked = await userRegistry.locked(1);
      assert.equal(isLocked, false, 'locked');
    });

    it('should not gives unlock for user 8', async function () {
      await assertRevert(userRegistry.locked(6));
    });

    it('should returns valid for account1 addresses', async function () {
      const isAddress1Valid = await userRegistry.isAddressValid(accounts[1]);
      assert.equal(isAddress1Valid, true, 'isAddress1Valid');
      const isAddress4Valid = await userRegistry.isAddressValid(accounts[4]);
      assert.equal(isAddress4Valid, true, 'isAddress4Valid');
    });

    it('should returns valid for account1', async function () {
      const isValid = await userRegistry.isValid(1);
      assert.equal(isValid, true, 'isValid');
    });

    it('should gives invalid for account3', async function () {
      const isValid = await userRegistry.isValid(3);
      assert.equal(isValid, false, 'isValid');
    });

    it('should returns invalid for account2 address', async function () {
      const isAddressValid = await userRegistry.isAddressValid(accounts[2]);
      assert.equal(isAddressValid, false, 'isAddressValid');
    });

    it('should not let an address being registered twice', async function () {
      await assertRevert(userRegistry.registerUser(accounts[0], dayPlusOneTime));
    });

    it('should not let an address being attached twice to same user', async function () {
      await assertRevert(userRegistry.attachAddress(1, accounts[0]));
    });

    it('should not let an address being attached twice to different user', async function () {
      await assertRevert(userRegistry.attachAddress(2, accounts[0]));
    });

    it('should not let an address not attached being detached', async function () {
      await assertRevert(userRegistry.detachAddress(accounts[9]));
    });

    it('should lock a user', async function () {
      await userRegistry.lockUser(1);
      const locked = await userRegistry.locked(1);
      assert.equal(locked, true, 'locked');
    });

    it('should not let a locked user being locked again', async function () {
      await userRegistry.lockUser(1);
      await assertRevert(userRegistry.lockUser(1));
    });

    it('should not let an unlocked user being unlocked again', async function () {
      await assertRevert(userRegistry.unlockUser(1));
    });

    it('should lock many users', async function () {
      await userRegistry.lockManyUsers([1, 2]);
      const locked1 = await userRegistry.locked(1);
      assert.equal(locked1, true, 'locked0');
      const locked2 = await userRegistry.locked(2);
      assert.equal(locked2, true, 'locked1');
    });

    it('should detach an address', async function () {
      await userRegistry.detachAddress(accounts[4]);
      const userId = await userRegistry.userId(accounts[4]);
      assert.equal(userId, 0, 'userId');
    });

    it('should detach many addresses', async function () {
      await userRegistry.detachManyAddresses([accounts[1], accounts[2], accounts[4]]);
      const userId2 = await userRegistry.userId(accounts[1]);
      assert.equal(userId2, 0, 'userId2');
      const userId3 = await userRegistry.userId(accounts[2]);
      assert.equal(userId3, 0, 'userId3');
      const userId4 = await userRegistry.userId(accounts[4]);
      assert.equal(userId4, 0, 'userId4');
    });

    it('should update user', async function () {
      await userRegistry.updateUser(1, dayPlusTwoTime, true);

      const validUntilTime = await userRegistry.validUntilTime(1);
      assert.equal(validUntilTime, dayPlusTwoTime, 'validUntilTime');
      const locked = await userRegistry.locked(1);
      assert.equal(locked, true, 'locked');
    });

    it('should update many users', async function () {
      await userRegistry.updateManyUsers([ 1, 2 ], dayPlusTwoTime, true);

      const validUntilTime1 = await userRegistry.validUntilTime(1);
      assert.equal(validUntilTime1, dayPlusTwoTime, 'validUntilTime');
      const locked1 = await userRegistry.locked(1);
      assert.equal(locked1, true, 'locked');
     
      const validUntilTime2 = await userRegistry.validUntilTime(2);
      assert.equal(validUntilTime2, dayPlusTwoTime, 'validUntilTime2');
      const locked2 = await userRegistry.locked(2);
      assert.equal(locked2, true, 'locked');
    });

    it('should update user extended', async function () {
      await userRegistry.updateUserExtended(1, 1, 100);

      const extended1 = await userRegistry.extended(1, 1);
      assert.equal(extended1, 100, 'extended');
    });

    it('should update many users extended', async function () {
      await userRegistry.updateManyUsersExtended([ 1, 2 ], 1, 100);

      const extended1 = await userRegistry.extended(1, 1);
      assert.equal(extended1, 100, 'extended1');
      const extended2 = await userRegistry.extended(2, 1);
      assert.equal(extended2, 100, 'extended2');
    });
  });
 
  describe('with 4 accounts and with 2 accounts locked', function () {
    beforeEach(async function () {
      userRegistry = await UserRegistry.new([accounts[0], accounts[1], accounts[2], accounts[3]], dayPlusOneTime);
      await userRegistry.lockManyUsers([ 2, 3 ]);
    });

    it('should unlock a user', async function () {
      await userRegistry.unlockUser(2);
      const locked = await userRegistry.locked(2);
      assert.equal(locked, false, 'locked');
    });

    it('should unlock many users', async function () {
      await userRegistry.unlockManyUsers([ 2, 3 ]);

      const locked2 = await userRegistry.locked(2);
      assert.equal(locked2, false, 'locked2');
      const locked3 = await userRegistry.locked(3);
      assert.equal(locked3, false, 'locked3'); ;
    });
  });
});
