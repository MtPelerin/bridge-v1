pragma solidity ^0.4.24;

import "../token/MintableBridgeToken.sol";


/**
 * @title StandardTokenMock
 * @dev Mock the StandardToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract MintableBridgeTokenMock is MintableBridgeToken {

  // Allow to test behavior in case of mint failure
  bool mintEnabled = true;

  constructor(string _name, string _symbol)
    MintableBridgeToken(_name, _symbol) public
  {}

  function enableMinting(bool _mintEnabled) public {
    mintEnabled = _mintEnabled;
  }

  function mint(address _to, uint256 _amount) public returns (bool) {
    if (mintEnabled) {
      return super.mint(_to, _amount);
    }
    return false;
  }
}
