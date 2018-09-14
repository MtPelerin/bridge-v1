pragma solidity ^0.4.24;

import "../../multisig/private/MultiSig.sol";
import "./CMTAShareholderAgreement.sol";
import "./CMTAPocToken.sol";


/**
 * @title CMTABoardSig
 * @dev CMTABoardSig contract
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
 *
 * Error messages
 * E01: Agreement must exist
 * E02: Agreement must belong to this contract
 * E03: Agreement must have a token configured
 */
contract CMTABoardSig is MultiSig {

  CMTAPocToken public token;
  CMTAShareholderAgreement public agreement;

  /**
   * @dev constructor function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    MultiSig(_addresses, _threshold)
  {
  }

  /**
   * @dev issue shares
   */
  function issueShares(
    CMTAShareholderAgreement _agreement,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV)
    thresholdRequired(threshold, _sigR, _sigS, _sigV) public
  {
    require(address(agreement) == address(0), "E01");
    require(_agreement.owner() == address(this), "E02");
    require(_agreement.token() != address(0), "E03");

    agreement = _agreement;
    token = _agreement.token();
  }
}
