pragma solidity ^0.4.24;

import "./component/SeizableToken.sol";
import "./component/TokenWithClaims.sol";
import "./component/TokenWithRules.sol";
import "../interface/IRule.sol";
import "../interface/IClaimable.sol";


/**
 * @title BridgeToken
 * @dev BridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract BridgeToken is TokenWithRules, TokenWithClaims, SeizableToken {
  string public name;
  string public symbol;

  /**
   * @dev constructor
   */
  constructor(string _name, string _symbol) 
    TokenWithRules(new IRule[](0))
    TokenWithClaims(new IClaimable[](0)) public
  {
    name = _name;
    symbol = _symbol;
  }
}

