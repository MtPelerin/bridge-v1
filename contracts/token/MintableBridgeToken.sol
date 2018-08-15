pragma solidity ^0.4.24;

import "./ProvableOwnershipToken.sol";
import "./MintableBridgeToken.sol";
import "./BridgeToken.sol";
import "./MintableToken.sol";


/**
 * @title MintableBridgeToken
 * @dev MintableBridgeToken contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract MintableBridgeToken is MintableToken, BridgeToken {

  string public name;
  string public symbol;

  uint public decimals = 18;

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

