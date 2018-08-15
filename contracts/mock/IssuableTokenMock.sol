pragma solidity ^0.4.24;

import "../token/IssuableToken.sol";


/**
 * @title IssuableTokenMock
 * @dev Mock the IssuableToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract IssuableTokenMock is IssuableToken {

  constructor(address initialAccount, uint initialBalance) public {
    balances[initialAccount] = initialBalance;
    totalSupply_ = initialBalance;
    allTimeIssued = initialBalance;
  }

}
