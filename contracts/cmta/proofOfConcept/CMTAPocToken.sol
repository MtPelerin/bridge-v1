pragma solidity ^0.4.24;

import "./CMTARestrictedToken.sol";
import "../../token/IssuableToken.sol";


/**
 * @title CMTAPocToken
 * @dev CMTAPocToken contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract CMTAPocToken is CMTARestrictedToken, IssuableToken {
  string public name;
  string public symbol;

  uint public decimals = 0;

  /**
   * @dev called by the owner to construct the CMTAPocToken
   */
  constructor(string _name, string _symbol) public {
    name = _name;
    symbol = _symbol;
  }
}

