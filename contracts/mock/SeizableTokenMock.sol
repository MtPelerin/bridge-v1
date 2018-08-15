pragma solidity ^0.4.24;

import "../token/SeizableToken.sol";


/**
 * @title SeizableTokenMock
 * @dev Mock the SeizableToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract SeizableTokenMock is SeizableToken {

  constructor(address initialAccount, uint initialBalance) public {
    balances[initialAccount] = initialBalance;
    totalSupply_ = initialBalance;
  }

}
