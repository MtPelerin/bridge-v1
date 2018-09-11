pragma solidity ^0.4.24;

import "../token/MintableBridgeToken.sol";


/**
 * @title StandardTokenMock
 * @dev Mock the StandardToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
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
