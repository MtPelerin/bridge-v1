pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../interface/ISaleConfig.sol";
import "../StateMachine.sol";


/**
 * @title MPLTokensalePlan
 * @dev MPLTokensalePlan contract
 * Handle the sale plan
 * The step always evolve forward
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
 * E01: Not the current step
 * E02: Interval ends before it start
 * E03: Current step is before
 * E04: Current step is after
 * E05: A plan already exists
 * E06: Steps are defined in wrong order
*/
contract MPLTokensalePlan is StateMachine {
  // The Step enum defines the plan of the sale
  enum Stepname {
    // Contract have been created
    CREATED,
    // Contract is configured:
    // - token is not premint and is locked
    // - sale will go live at the configured date
    READY,
    // The sale is live
    LIVE, // Automatic step
    // The sale is over. Investments are being reviewed
    REVIEW, // Automatic step
    // Preparation of the Minting
    // Refunds of users who have over invested
    PREPARE,
    // Minting of the token. 
    MINT, // Automatic step
    // Finalize remaining minting
    FINALIZE,
    // Terminate the minting
    // Release the token
    RELEASED
  }

  ISaleConfig public saleConfig;

  constructor(ISaleConfig _saleConfig) public {
    saleConfig = _saleConfig;
  }

  modifier whenStepIs(Stepname _name) {
    require(_name == Stepname(currentStep()), "E01");
    _;
  }

  modifier whenBetweenSteps(Stepname _start, Stepname _end) {
    // check call parameters 
    require(_start < _end, "E02");

    // check current step value
    Stepname _step = Stepname(currentStep());
    require(_step >= _start, "E03");
    require(_step <= _end, "E04");
    _;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function saleConfig() public view returns (ISaleConfig) {
    return saleConfig;
  }

  /**
   * @dev define the plan for the tokensale
   **/
  function plan() public onlyOwner {
    require(stepsCount() == 0, "E05");

    uint256 saleLiveAt = saleConfig.openingTime();
    uint256 duration = saleConfig.duration();
    uint256 mintDuration = saleConfig.mintingDelay();

    evalNewStep(Stepname.CREATED, 0, 0);
    evalNewStep(Stepname.READY, saleLiveAt, 0);
    evalNewStep(Stepname.LIVE, 0, duration);
    evalNewStep(Stepname.REVIEW, 0, 0);
    evalNewStep(Stepname.PREPARE, 0, 0);
    evalNewStep(Stepname.MINT, 0, mintDuration);
    evalNewStep(Stepname.FINALIZE, 0, 0);
    evalNewStep(Stepname.RELEASED, 0, 0);
  }

  /**
   * @dev allow an adjustment of the starting date
   **/
  function updateSaleOpeningTime(
    uint256 _newOpeningTime)
    public onlyOwner whenStepIs(Stepname.READY)
  {
    updateCurrentStep(_newOpeningTime, 0);
  }

  /**
   * @dev As we are relying on enum ordering
   * It's safer to check that each step is correctly
   * declared with its correct name
   **/
  function evalNewStep(
    Stepname _name, uint256 _endTime, uint256 _delay
  ) private 
  {
    require(
      _name == Stepname(addStep(_endTime, _delay)),
      "E06");
  }
}
