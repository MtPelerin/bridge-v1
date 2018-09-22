pragma solidity ^0.4.24;

import "../proofOfConcept/CMTARestrictedToken.sol";
import "../proofOfConcept/CMTAAgreement.sol";


/**
 * @title CMTARestrictedTokenMock
 * @dev Mock the CMTARestrictedToken class
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 */
contract CMTARestrictedTokenMock is CMTARestrictedToken {

  constructor(
    address initialAccount,
    uint initialBalance,
    bytes32 _agreementHash)
    public CMTAAgreement(_agreementHash)
  {
    totalSupply_ = initialBalance;
    balances[initialAccount] = initialBalance;
  }

}
