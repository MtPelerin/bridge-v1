pragma solidity ^0.4.24;

import "./RestrictedToken.sol";
import "../token/IssuableToken.sol";


/**
 * @title DemoToken
 * @dev DemoToken contract
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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

