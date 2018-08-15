pragma solidity ^0.4.24;


/**
 * @title IStateMachine
 * @dev IStateMachine interface
 * Implements a programmable state machine
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract IStateMachine {
  function stepsCount() public view returns (uint256);
  function currentStep() public view returns (uint256);
}
