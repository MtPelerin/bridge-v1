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

  enum Pass {
    NONE,
    RECEIVE,
    SEND,
    BOTH
  }

  struct ScheduledLock {
    uint256 startAt;
    uint256 endAt;
    bool inverted;
  }

  mapping(address => Pass) individualPasses;
  ScheduledLock lock = ScheduledLock(0, 0, false);

  /**
   * @dev scheduledStartAt
   */
  function scheduledStartAt() public view returns (uint256) {
    return lock.startAt;
  }

  /**
   * @dev scheduledEndAt
   */
  function scheduledEndAt() public view returns (uint256) {
    return lock.endAt;
  }

  /**
   * @dev lock inverted
   */
  function lockInverted() public view returns (bool) {
    return lock.inverted;
  }

  /**
   * @dev currentLock
   */
  function currentLock() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return (lock.startAt <= now && lock.endAt > now)
      ? !lock.inverted : lock.inverted;
  }

  /**
   * @dev individualPass
   */
  function individualPass(address _address)
    public view returns (Pass)
  {
    return individualPasses[_address];
  }

  /**
   * @dev can the address send
   */
  function canSend(address _address) public view returns (bool) {
    if(currentLock()) {
      return (individualPasses[_address] == Pass.BOTH ||
        individualPasses[_address] == Pass.SEND);
    }
    return true;
  }

  /**
   * @dev can the address receive
   */
  function canReceive(address _address) public view returns (bool) {
    if(currentLock()) {
      return (individualPasses[_address] == Pass.BOTH ||
        individualPasses[_address] == Pass.RECEIVE);
    }
    return true;
  }

  /**
   * @dev allow authority to provide a pass to an address
   */
  function definePass(address _address, uint256 _lock)
    public onlyAuthority returns (bool)
  {
    individualPasses[_address] = Pass(_lock);
    emit PassDefinition(_address, Pass(_lock));
  }

  /**
   * @dev allow authority to provide addresses with lock passes
   */
  function defineManyPasses(address[] _addresses, uint256 _lock)
    public onlyAuthority returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      definePass(_addresses[i], _lock);
    }
  }

  /**
   * @dev schedule lock
   */
  function scheduleLock(
    uint256 _startAt, uint256 _endAt, bool _inverted)
    public onlyAuthority returns (bool)
  {
    require(_startAt <= _endAt);
    lock = ScheduledLock(_startAt, _endAt, _inverted);
    emit LockDefinition(lock.startAt, lock.endAt, lock.inverted);
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address /*_address*/) public view returns (bool) {
    return true;
  }

  /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return canSend(_from) && canReceive(_to);
  }

  event LockDefinition(uint256 startAt, uint256 endAt, bool inverted);
  event PassDefinition(address _address, Pass pass);
}
