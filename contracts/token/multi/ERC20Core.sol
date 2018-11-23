pragma solidity ^0.4.24;


import "./TokenCore.sol";


/**
 * @title ERC20Core
 * @dev ERC20Core contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract ERC20Core is TokenCore {

  struct TokenDetails {
    string name;
    string symbol;
    uint256 decimal;
  }
  mapping(address => TokenDetails) tokensDetails;
  mapping(string => address) symbolRegistry;

  function name() public view returns (string) {
    return tokensDetails[msg.sender].name;
  }

  function symbol() public view returns (string) {
    return tokensDetails[msg.sender].symbol;
  }

  function decimal() public view returns (uint256) {
    return tokensDetails[msg.sender].decimal;
  }

  function tokenAddressBySymbol(string _symbol) public view returns (address) {
    return symbolRegistry[_symbol];
  }

  function setupTokenDetails(address _token, string _name, string _symbol, uint256 _decimal) public {
    require(symbolRegistry[_symbol] == address(0));
    tokensDetails[_token] =
      TokenDetails(_name, _symbol, _decimal);
    symbolRegistry[_symbol] = _token;
  }
}
