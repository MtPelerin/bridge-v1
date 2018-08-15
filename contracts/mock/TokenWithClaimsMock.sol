pragma solidity ^0.4.24;

import "../interface/IClaimable.sol";
import "../token/TokenWithClaims.sol";


/**
 * @title TokenWithClaimsMock
 * @dev Mock the TokenWithClaims class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract TokenWithClaimsMock is TokenWithClaims {

  constructor(
    IClaimable[] _claims,
    address _initialAccount, 
    uint _initialBalance
  ) TokenWithClaims(_claims) public
  {
    balances[_initialAccount] = _initialBalance;
    totalSupply_ = _initialBalance;
  }

}
