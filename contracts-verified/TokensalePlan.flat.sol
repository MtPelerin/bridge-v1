/**
 * TokensalePlan.sol
 * MPS Token (Mt Pelerin Share) token sale PLAN : private round.

 * More info about MPS : https://github.com/MtPelerin/MtPelerin-share-MPS

 * The unflattened code is available through this github tag:
 * https://github.com/MtPelerin/MtPelerin-protocol/tree/etherscan-verify-batch-1

 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved

 * @notice All matters regarding the intellectual property of this code 
 * @notice or software are subject to Swiss Law without reference to its 
 * @notice conflicts of law rules.

 * @notice License for each contract is available in the respective file
 * @notice or in the LICENSE.md file.
 * @notice https://github.com/MtPelerin/

 * @notice Code by OpenZeppelin is copyrighted and licensed on their repository:
 * @notice https://github.com/OpenZeppelin/openzeppelin-solidity
 */
 

pragma solidity ^0.4.24;

// File: contracts/zeppelin/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/interface/ISaleConfig.sol

/**
 * @title ISaleConfig interface
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice Please refer to the top of this file for the license.
 */
contract ISaleConfig {

  struct Tokensale {
    uint256 lotId;
    uint256 tokenPriceCHFCent;
  }

  function tokenSupply() public pure returns (uint256);
  function tokensaleLotSupplies() public view returns (uint256[]);

  function tokenizedSharePercent() public pure returns (uint256); 
  function tokenPriceCHF() public pure returns (uint256);

  function minimalCHFInvestment() public pure returns (uint256);
  function maximalCHFInvestment() public pure returns (uint256);

  function tokensalesCount() public view returns (uint256);
  function lotId(uint256 _tokensaleId) public view returns (uint256);
  function tokenPriceCHFCent(uint256 _tokensaleId)
    public view returns (uint256);
}

// File: contracts/zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/interface/IStateMachine.sol

/**
 * @title IStateMachine
 * @dev IStateMachine interface
 * Implements a programmable state machine
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice Please refer to the top of this file for the license.
 */
contract IStateMachine {
  function stepsCount() public view returns (uint256);
  function currentStep() public view returns (uint256);
}

// File: contracts/StateMachine.sol

/**
 * @title StateMachine
 * @dev StateMachine contract
 * Implements a programmable state machine
 * The machine can follow automatically transition from
 * one state to another if one of the condition is matched:
 * - transitionEndTime is not 0 and lower than current time
 * - transitionDelay is not 0 and lower than the delay since
 *   the beginning of the step (ie stepTime)
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice Please refer to the top of this file for the license.
 *
 * Error messages
 * SM01: No plans are configured
 * SM02: Historical steps must happened in the past
 * SM03: New step must be no earlier the previous one
 * SM04: There is no transitions to update
 * SM05: Transition update must be in the future
 * SM06: Current step is already the last step
 * SM07: The current step has already a transition
*/
contract StateMachine is IStateMachine, Ownable {
  using SafeMath for uint256;

  struct Step {
    uint256 stepTime;

    // Automatic transition attributes
    uint256 transitionEndTime;
    uint256 transitionDelay;
  }
  Step[] private steps;
  uint8 private manualStepId;

  /**
   * @dev stepTime
   **/
  function stepTime(uint256 _stepId) public view returns (uint256) {
    return steps[_stepId].stepTime;
  }

  /**
   * @dev transitionEndTime
   **/
  function transitionEndTime(uint256 _stepId) public view returns (uint256) {
    return steps[_stepId].transitionEndTime;
  }

  /**
   * @dev transitionDelay
   **/
  function transitionDelay(uint256 _stepId) public view returns (uint256) {
    return steps[_stepId].transitionDelay;
  }

  /**
   * @dev stepsCount
   **/
  function stepsCount() public view returns (uint256) {
    return steps.length;
  }

  /**
   * @dev stepEndTime
   * returns the step end time based on its start time
   **/
  function stepEndTime(uint256 _stepId, uint256 _startedAt)
    public view returns (uint256)
  {
    uint256 endTime = ~uint256(0);
    Step memory step = steps[_stepId];

    if (step.transitionDelay != 0) {
      endTime = _startedAt.add(step.transitionDelay);
    }
    if (step.transitionEndTime != 0 && step.transitionEndTime < endTime) {
      endTime = step.transitionEndTime;
    }
    return endTime;
  }

  /**
   * @dev currentStep
   * returns the current step
   **/
  function currentStep() public view returns (uint256) {
    require(steps.length > 0, "SM01");
    uint256 currentStepId = manualStepId;

    uint256 currentStepTime = steps[manualStepId].stepTime;
    for (uint256 i = currentStepId; i < steps.length; i++) {
      uint256 endTime = stepEndTime(i, currentStepTime);
      if (endTime >= currentTime() || (i == steps.length-1)) {
        currentStepId = i;
        break;
      }
      currentStepTime = endTime;
    }

    return currentStepId;
  }

  /**
   * @dev addStep
   * If there will be automatically a transition to the next step
   * when either the end time or the delay after the begining of that step
   * expires
   * @param _transitionEndTime plan end time for the step
   * @param _transitionDelay plan delay for that step
   **/
  function addStep(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) internal onlyOwner returns (uint256)
  {
    uint256 _stepTime = 0;
    if (steps.length == 0) {
      _stepTime = currentTime();
    }
    steps.push(Step(_stepTime, _transitionEndTime, _transitionDelay));
    return steps.length-1;
  }

  /**
   * @dev addHistoricalStep
   * Allow to add step in the past
   *
   * @param _stepTime historical step time
   * @param _transitionEndTime plan end time for the step
   * @param _transitionDelay plan delay for that step
   **/
  function addHistoricalStep(
    uint256 _stepTime,
    uint256 _transitionEndTime,
    uint256 _transitionDelay) internal onlyOwner returns (uint256)
  {
    // the stepTime must be in the past and consecutive to previous steps
    require(_stepTime < currentTime(), "SM02");
    if (steps.length > 0) {
      require(_stepTime > steps[steps.length-1].stepTime, "SM03");
    }

    uint256 newId = addStep(_transitionEndTime, _transitionDelay);
    steps[newId].stepTime = _stepTime;
    return newId;
  }

  /**
   * @dev updateCurrentStep
   * Allow adjustement of the current step planning
   * It is restricted to the following cases:
   * - There is already a transition planned
   * - The adjustement must be in the future
   *   if the transition EndTime is updated.
   *   The check on the transition Delay is too costly
   **/
  function updateCurrentStep(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) internal onlyOwner
  {
    uint256 currentStepId = currentStep();

    if (_transitionEndTime > 0) {
      require(steps[currentStepId].transitionEndTime > 0, "SM04");
      require(_transitionEndTime > currentTime(), "SM05");
      steps[currentStepId].transitionEndTime = _transitionEndTime;
    }

    if (_transitionDelay > 0) {
      require(steps[currentStepId].transitionDelay > 0, "SM04");
      steps[currentStepId].transitionDelay = _transitionDelay;
    }
  }

  /**
   * @dev nextStep
   * progress to the next step
   * cannnot be done when either:
   * - the current step is the last step
   * - the current step has already a planned transition
   **/
  function nextStep() internal {
    uint256 currentStepId = currentStep();
    require(currentStepId < steps.length - 1, "SM06");

    // Prevent manual iteration over next steps
    require(
      steps[currentStepId].transitionEndTime == 0 &&
      steps[currentStepId].transitionDelay == 0, "SM07");

    manualStepId = uint8(currentStepId.add(1));
    steps[manualStepId].stepTime = currentTime();
  }

  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}

// File: contracts/tokensale/TokensalePlan.sol

/**
 * @title TokensalePlan
 * @dev TokensalePlan contract
 * Handle the sale plan
 * The step always evolve forward
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice Please refer to the top of this file for the license.
 *
 * Error messages
 * TP01: Not allowed during current step
 * TP02: Interval ends before it starts
 * TP03: Current step is before allowed step for this action
 * TP04: Current step is after allowed step for this action
 * TP05: A plan already exists
 * TP06: Steps are defined in wrong order
*/
contract TokensalePlan is StateMachine {
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
  uint256 public tokensaleId;

  constructor(ISaleConfig _saleConfig, uint256 _tokensaleId) public {
    saleConfig = _saleConfig;
    tokensaleId = _tokensaleId;
  }

  modifier whenStepIs(Stepname _name) {
    require(_name == Stepname(currentStep()), "TP01");
    _;
  }

  modifier whenBetweenSteps(Stepname _start, Stepname _end) {
    // check call parameters 
    require(_start < _end, "TP02");

    // check current step value
    Stepname _step = Stepname(currentStep());
    require(_step >= _start, "TP03");
    require(_step <= _end, "TP04");
    _;
  }

  /**
   * @dev getter need to be declared to comply with ITokensale interface
   */
  function saleConfig() public view returns (ISaleConfig) {
    return saleConfig;
  }

  /**
   * @dev getter need to be declared to comply with ITokensale interface
   */
  function tokensaleId() public view returns (uint256) {
    return tokensaleId;
  }

  /**
   * @dev define the plan for the tokensale
   **/
  function plan(
    uint256 _saleLiveAt,
    uint256 _duration,
    uint256 _mintDuration) public onlyOwner
  {
    require(stepsCount() == 0, "TP05");

    evalNewStep(Stepname.CREATED, 0, 0);
    evalNewStep(Stepname.READY, _saleLiveAt, 0);
    evalNewStep(Stepname.LIVE, 0, _duration);
    evalNewStep(Stepname.REVIEW, 0, 0);
    evalNewStep(Stepname.PREPARE, 0, 0);
    evalNewStep(Stepname.MINT, 0, _mintDuration);
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
      "TP06");
  }
}
