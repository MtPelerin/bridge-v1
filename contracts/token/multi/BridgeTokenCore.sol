pragma solidity ^0.4.23;


import "./TokenCore.sol";


/**
 * @title BridgeTokenCore
 * @dev BridgeTokenCore contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract BridgeTokenCore is TokenCore {

  struct TokenData {
    string name;
    string symbol;
    uint256 decimal;
  }
  mapping(bytes4 => TokenData) tokensData;

  function name(bytes4 _key) public view returns (string) {
    return tokensData[_key].name;
  }

  function symbol(bytes4 _key) public view returns (string) {
    return tokensData[_key].symbol;
  }

  function decimal(bytes4 _key) public view returns (uint256) {
    return tokensData[_key].decimal;
  }
}
