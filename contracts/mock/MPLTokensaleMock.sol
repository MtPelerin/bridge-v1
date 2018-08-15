pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../interface/IUserRegistry.sol";
import "../tokensale/MPLTokensale.sol";


/**
 * @title MPLTokensaleMock
 * @dev MPLTokensaleMock contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract MPLTokensaleMock is MPLTokensale {

  constructor(
    address _vault, 
    ISaleConfig _saleConfig,
    IUserRegistry _userRegistry)
    MPLTokensale(_vault, _saleConfig, _userRegistry) public
  {
  }

  function setStep(Stepname _name) public onlyOwner {
    while (currentStep() < uint256(_name)) {
      nextStep();
    }
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
    uint256 /*_transitionEndTime*/,
    uint256 /*_transitionDelay*/) internal returns (uint256)
  {
    return super.addStep(0,0);
  }
}
