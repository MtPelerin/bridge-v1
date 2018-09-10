pragma solidity ^0.4.24;

import "./RestrictedToken.sol";
import "../token/IssuableToken.sol";


/**
 * @title DemoToken
 * @dev DemoToken contract
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
contract DemoToken is RestrictedToken, IssuableToken {
  string public name;
  string public symbol;

  uint public decimals = 18;

  /**
   * @dev called by the owner to construct the DemoToken
   */
  constructor(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
  }
}

