pragma solidity ^0.4.24;

import "../interface/IRule.sol";


/**
 * @title ScheduledNoRule
 * @dev ScheduledNoRule interface
 * The rule returns false whenever we are within time definition
 * Usefull for testing IWithRule implementation
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract ScheduledNoRule is IRule {
  uint256 startTime;
  uint256 endTime;

  // Rule applies inside the schedule when inverted is false
  // Rule applies outside the schedule when inverted is true
  bool inverted;

  /**
   * @dev constructor
   * @param _startTime start time in seconds
   * @param _delay delay in seconds since startTime
   * @param _endTime end time in seconds
   * @param _inverted whether the restriction is within the schedule or outside
   */
  constructor(uint256 _startTime, uint256 _delay, uint256 _endTime, bool _inverted) public {
    startTime = _startTime;
    endTime = ~uint256(0);
    if(_delay != 0) {
      endTime = _startTime + _delay;
    }

    if(_endTime != 0 && _endTime < endTime) {
      endTime = _endTime;
    }

    inverted = _inverted;
  }

  function scheduleOn() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    uint256 currentTime = now;
    return currentTime >= startTime
      && currentTime <= endTime;
  }

  function isAddressValid(address /* _from */) public view returns (bool) {
    return inverted ? !scheduleOn() : scheduleOn();
  }

  function isTransferValid(
    address /* _from */,
    address /*_to */,
    uint256 /*_amount */)
    public view returns (bool)
  {
    return inverted ? !scheduleOn() : scheduleOn();
  }
}
