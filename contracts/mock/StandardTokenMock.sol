pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";


/**
 * @title StandardTokenMock
 * @dev Mock the StandardToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract StandardTokenMock is StandardToken {

  constructor(address initialAccount, uint initialBalance) public {
    totalSupply_ = initialBalance;
    balances[initialAccount] = initialBalance;
  }

}
