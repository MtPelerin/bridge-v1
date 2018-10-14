pragma solidity ^0.4.24;

import "../interface/IRule.sol";
import "../token/component/TokenWithRules.sol";


/**
 * @title TokenWithRulesMock
 * @dev Mock the TokenWithRules class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
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
