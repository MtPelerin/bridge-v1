pragma solidity ^0.4.24;

import "./SeizableToken.sol";
import "./ProvableOwnershipToken.sol";
import "./TokenWithClaims.sol";
import "./TokenWithRules.sol";
import "../interface/IRule.sol";
import "../interface/IClaimable.sol";


/**
 * @title BridgeToken
 * @dev BridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract BridgeToken is ProvableOwnershipToken, TokenWithRules, TokenWithClaims, SeizableToken {
  string public name;
  string public symbol;

  uint public decimals = 18;

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

