pragma solidity ^0.4.24;

import "../multisig/private/MultiSig.sol";
import "../token/BridgeToken.sol";


/**
 * @title BoardSig
 * @dev BoardSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 *
 * Error messages
 */
contract BoardSig is MultiSig {
  bytes32 public constant TOKENIZE = keccak256("TOKENIZE");

  string public companyName;

  string public country;
  string public registeredNumber;

  BridgeToken public token;

  /**
   * @dev constructor function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    MultiSig(_addresses, _threshold)
  {
  }

  /**
   * @dev returns hash of hashed "TOKENIZE"+ token address + document hash
   */
  function tokenizeHash(BridgeToken _token, bytes32 _hash)
    public pure returns (bytes32)
  {
    return keccak256(
      abi.encode(TOKENIZE, address(_token), _hash)
    );
  }

  /**
   * @dev tokenize shares
   */
  function tokenizeShares(
    BridgeToken _token,
    bytes32 _hash,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV) public
    thresholdRequired(address(this), 0,
      abi.encodePacked(tokenizeHash(_token, _hash)),
      0, threshold, _sigR, _sigS, _sigV)
  {
    updateReplayProtection();
    token = _token;

    emit ShareTokenization(_token, _hash);
  }

  /**
   * @dev add board meeting
   */
  function addBoardMeeting(
    bytes32 _hash,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV) public
    thresholdRequired(address(this), 0,
      abi.encodePacked(_hash),
      0, threshold, _sigR, _sigS, _sigV)
  {
    emit BoardMeetingHash(_hash);
  }

  event ShareTokenization(BridgeToken token, bytes32 hash);
  event BoardMeetingHash(bytes32 hash);

}
