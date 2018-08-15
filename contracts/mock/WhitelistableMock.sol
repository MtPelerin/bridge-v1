pragma solidity ^0.4.24;

import "../Whitelistable.sol";


/**
 * @title WhitelistableMock
 * @dev WhitelistableMock contract
 *
 * @author cyril.lapinte@mtpelerin.com
  */
contract WhitelistableMock is Whitelistable {

  bool public success;
  
  function testMe() public onlyWhitelisted(msg.sender) {
    success = true; 
  }
}
