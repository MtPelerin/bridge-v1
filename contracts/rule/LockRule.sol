pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../Authority.sol";
import "../interface/IRule.sol";


/**
 * @title LockRule
 * @dev LockRule contract
 * This rule allow to lock assets for a period of time
 * for event such as investment vesting
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: The address is locked
 */
contract LockRule is IRule, Authority {

  enum Lock {
    BOTH,
    RECEIVE,
    SEND,
    NONE
  }

  struct ScheduledLock {
    uint256 startAt;
    uint256 endAt;
    Lock inactive;
    Lock active;
  }

  mapping(address => Lock) individual;
  ScheduledLock global = ScheduledLock(0, 0, Lock.NONE, Lock.BOTH);

  /**
   * @dev scheduleStartAt
   */
  function scheduleStartAt() public view returns (uint256) {
    return global.startAt;
  }

  /**
   * @dev scheduleEndAt
   */
  function scheduleEndAt() public view returns (uint256) {
    return global.endAt;
  }

  /**
   * @dev global inactive restriction
   */
  function globalActiveLock() public view returns (Lock) {
    return global.active;
  }

  /**
   * @dev global inactive restriction
   */
  function globalInactiveLock() public view returns (Lock) {
    return global.active;
  }

  /**
   * @dev global restriction
   */
  function globalLock() public view returns (Lock) {
    // solium-disable-next-line security/no-block-members
    return (global.startAt <= now && global.endAt > now)
      ? global.active : global.inactive;
  }

  /**
   * @dev individualLock
   */
  function individualLock(address _address)
    public view returns (Lock)
  {
    return individual[_address];
  }

  /**
   * @dev can the address send
   * If defined individual rules have precedence over global ones
   */
  function canSend(address _address) public view returns (bool) {
    if (individual[_address] == Lock.NONE ||
      individual[_address] == Lock.RECEIVE) {
      return true;
    }

    Lock lock = globalLock();
    if (lock == Lock.NONE ||
      lock == Lock.RECEIVE) {
      return true;
    }
    return false;
  }

  /**
   * @dev can the address receive
   * If defined individual rules have precedence over global ones
   */
  function canReceive(address _address) public view returns (bool) {
    if (individual[_address] == Lock.NONE ||
      individual[_address] == Lock.SEND) {
      return true;
    }

    Lock lock = globalLock();
    if (lock == Lock.NONE ||
      lock == Lock.SEND) {
      return true;
    }
    return false;
  }

  /**
   * @dev allow authority to lock the address
   */
  function lockAddress(address _address, Lock _lock)
    public onlyAuthority returns (bool)
  {
    individual[_address] = _lock;
    emit Locked(_address, _lock);
  }

  /**
   * @dev allow authority to lock several addresses
   */
  function lockManyAddresses(address[] _addresses, Lock _lock)
    public onlyAuthority returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      individual[_addresses[i]] = _lock;
      emit Locked(_addresses[i], _lock);
    }
  }

  /**
   * @dev lock all
   */
  function lockAll(
    uint256 _startAt,
    uint256 _endAt, Lock _active, Lock _inactive)
    public onlyAuthority returns (bool)
  {
    global = ScheduledLock(_startAt, _endAt, _active, _inactive);
    emit LockedAll(_startAt, _endAt, _active, _inactive);
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    return true;
  }

  /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return (!canSend(_from) && canReceive(_to));
  }

  event LockedAll(uint256 startAt, uint256 endAt, Lock active, Lock inactive);
  event Locked(address _address, Lock lock);
}
