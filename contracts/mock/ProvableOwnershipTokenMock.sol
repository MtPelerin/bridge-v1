pragma solidity ^0.4.24;

import "../token/component/ProvableOwnershipToken.sol";


/**
 * @title ProvableOwnershipTokenMock
 * @dev Mock the ProvableOwnershipToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * POTM01: Same number of holders and proofs must be provided
 * POTM02: Same number of holders and before must be provided
 */
contract ProvableOwnershipTokenMock is ProvableOwnershipToken {

  constructor(address _initialAccount, uint _initialBalance,
              address[] _proofsHolder, uint256[] _proofsAmount,
              uint256[] _proofsBefore) public {
    require(_proofsHolder.length == _proofsAmount.length, "POTM01");
    require(_proofsHolder.length == _proofsBefore.length, "POTM02");

    balances[_initialAccount] = _initialBalance;
    totalSupply_ = _initialBalance;

    for (uint256 i = 0; i < _proofsHolder.length; i++) {
      createProofInternal(
        _proofsHolder[i],
        _proofsAmount[i],
        _proofsBefore[i]);
    }
  }

}
