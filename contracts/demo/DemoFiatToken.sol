pragma solidity ^0.4.24;

import "../token/component/SeizableToken.sol";
import "./DemoToken.sol";


/**
 * @title DemoFiatToken
 * @dev DemoFiatToken contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 */
contract DemoFiatToken is DemoToken, SeizableToken {

  uint public decimals = 2;

  constructor(string _name, string _symbol)
    DemoToken(_name, _symbol) public
  { }
}

