pragma solidity ^0.4.24;

import "../StateMachine.sol";


/**
 * @title StateMachineMock
 * @dev StateMachineMock contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract StateMachineMock is StateMachine {

  function addStepPublic(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) public onlyOwner returns (uint256)
  {
    return addStep(_transitionEndTime, _transitionDelay);
  }

  function addHistoricalStepPublic(
    uint256 _stepTime,
    uint256 _transitionEndTime,
    uint256 _transitionDelay) public onlyOwner returns (uint256)
  {
    return addHistoricalStep(
      _stepTime, _transitionEndTime, _transitionDelay);
  }

  function updateCurrentStepPublic(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) public onlyOwner
  {
    updateCurrentStep(
      _transitionEndTime, _transitionDelay);
  }

  function nextStepPublic() public onlyOwner {
    nextStep();
  }

}
