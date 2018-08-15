pragma solidity ^0.4.24;

import "../interface/IRule.sol";
import "../token/TokenWithRules.sol";


// mock class using TokenWithRules
contract TokenWithRulesMock is TokenWithRules {

  constructor(
    IRule[] _rules,
    address _initialAccount,
    uint256 _initialBalance
  ) TokenWithRules(_rules) public
  {
    balances[_initialAccount] = _initialBalance;
    totalSupply_ = _initialBalance;
  }

}
