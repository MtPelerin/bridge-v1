pragma solidity ^0.4.24;

import "../token/ProvableOwnershipToken.sol";


/**
 * @title ProvableOwnershipTokenMock
 * @dev Mock the ProvableOwnershipToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: Same number of holders and proofs must be provided
 */
contract ProvableOwnershipTokenMock is ProvableOwnershipToken {

  constructor(address _initialAccount, uint _initialBalance,
              address[] _proofsHolder, uint256[] _proofsAmount) public {
    require(_proofsHolder.length == _proofsAmount.length, "E01");

    balances[_initialAccount] = _initialBalance;
    totalSupply_ = _initialBalance;

    for (uint256 i = 0; i < _proofsHolder.length; i++) {
      createProofInternal(_proofsHolder[i], _proofsAmount[i]);
    }
  }

}
