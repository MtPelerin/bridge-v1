pragma solidity ^0.4.24;

import "../token/SeizableToken.sol";
import "./DemoToken.sol";


/**
 * @title DemoFiatToken
 * @dev DemoFiatToken contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract DemoFiatToken is DemoToken, SeizableToken {

  uint public decimals = 2;

  constructor(string _name, string _symbol) DemoToken(_name, _symbol) public { }
}

