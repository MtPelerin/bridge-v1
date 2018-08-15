pragma solidity ^0.4.24;

import "../token/AuditableToken.sol";


/**
 * @title AuditableTokenMock
 * @dev Mock the AuditableToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract AuditableTokenMock is AuditableToken {

  constructor(address initialAccount, uint initialBalance) public {
    balances[initialAccount] = initialBalance;
  }

}
