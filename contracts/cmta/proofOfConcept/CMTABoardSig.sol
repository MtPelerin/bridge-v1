pragma solidity ^0.4.24;

import "../../multisig/private/MultiSig.sol";
import "./CMTAShareDistribution.sol";
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
 * E01: The owner of share distribution must be this contract
 * E02: This contract must be the token owner
 */
contract CMTABoardSig is MultiSig {
  bytes public constant TOKENIZE = abi.encodePacked(keccak256("TOKENIZE"));

  CMTAPocToken public token;

  /**
   * @dev constructor function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    MultiSig(_addresses, _threshold)
  {
  }

  /**
   * @dev tokenize shares
   */
  function tokenizeShares(
    CMTAShareDistribution _shareDistribution,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV) public
    thresholdRequired(address(_shareDistribution), 0, TOKENIZE, 0,
      threshold, _sigR, _sigS, _sigV)
  {
    require(_shareDistribution.owner() == address(this), "E01");

    CMTAPocToken newToken = _shareDistribution.token();
    require(newToken.owner() == address(this), "E02");

    token = newToken;
    emit ShareTokenization(_shareDistribution);
  }

  event ShareTokenization(CMTAShareDistribution distribution);
}
