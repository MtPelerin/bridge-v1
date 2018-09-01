pragma solidity ^0.4.24;

import "../demo/RestrictedToken.sol";


/**
 * @title RestrictedTokenMock
 * @dev Mock the RestrictedToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract RestrictedTokenMock is RestrictedToken {

  constructor(address initialAccount, uint initialBalance) public {
    totalSupply_ = initialBalance;
    balances[initialAccount] = initialBalance;
  }

}
