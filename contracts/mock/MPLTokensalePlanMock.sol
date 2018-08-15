pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../tokensale/MPLTokensalePlan.sol";


/**
 * @title MPLTokensalePlanMock
 * @dev MPLTokensalePlanMock contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract MPLTokensalePlanMock is MPLTokensalePlan {

  Step[] public mockSteps;

  constructor(ISaleConfig _saleConfig)
    MPLTokensalePlan(_saleConfig) public
  {
  }

  function mockedStepTransitionEndTime(uint256 _stepId)
    public view returns (uint256)
  {
    return mockSteps[_stepId].transitionEndTime;
  }

  function mockedStepTransitionDelay(uint256 _stepId)
    public view returns (uint256)
  {
    return mockSteps[_stepId].transitionDelay;
  }

  function dummyWhenStepIs(Stepname _name)
    public whenStepIs(_name) view returns (bool)
  {
    return true;
  }

  function dummyWhenBetweenSteps(Stepname _from, Stepname _to)
    public whenBetweenSteps(_from, _to) view returns (bool)
  {
    return true;
  }

  function nextStepPublic() public onlyOwner {
    nextStep();
  }

  /**
   * @dev to allow easy testing by pass the constraints
   * on time and delay and allow full manual testing
   * Value provided should be tested but the engine itself
   * should have been tested to ensure the value would be properly
   * executed
   **/
  function addStep(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) internal returns (uint256)
  {
    mockSteps.push(Step(0, _transitionEndTime, _transitionDelay));
    return super.addStep(0,0);
  }

  function updateCurrentStep(
    uint256 _transitionEndTime,
    uint256 _transitionDelay) internal onlyOwner
  {
    uint256 currentStepId = currentStep();
    mockSteps[currentStepId].transitionEndTime = _transitionEndTime;
    mockSteps[currentStepId].transitionDelay = _transitionDelay;
  }
}
