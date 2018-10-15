pragma solidity ^0.4.24;

import "./component/IssuableToken.sol";
import "./BridgeToken.sol";


/**
 * @title IssuableBridgeToken
 * @dev IssuableBridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract IssuableBridgeToken is BridgeToken, IssuableToken {

  string public name;
  string public symbol;

  /**
   * @dev constructor
   */
  constructor(string _name, string _symbol)
    BridgeToken(_name, _symbol) public
  {
    name = _name;
    symbol = _symbol;
  }
}

