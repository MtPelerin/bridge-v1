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
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 *
 * Error messages
 * CMTABS01: The owner of share distribution must be this contract
 * CMTABS02: This contract must be the token owner
 * CMTABS03: Unable to allocate shares
 */
contract CMTABoardSig is MultiSig {
  bytes32 public constant TOKENIZE = keccak256("TOKENIZE");
  bytes32 public constant ALLOCATE = keccak256("ALLOCATE");

  CMTAShareDistribution public distribution;
  CMTAPocToken public token;

  /**
   * @dev constructor function
   */
  constructor(address[] _addresses, uint8 _threshold) public
    MultiSig(_addresses, _threshold)
  {
  }

  /**
   * @dev tokenize hash
   */
  function tokenizeHash(CMTAShareDistribution _shareDistribution)
    public pure returns (bytes32)
  {
    return keccak256(
      abi.encode(TOKENIZE, address(_shareDistribution))
    );
  }

  /**
   * @dev allocate hash
   */
  function allocateHash(
    address[] _shareholders,
    uint256[] _amounts,
    uint256 _kycUntil) public pure returns (bytes32)
  {
    return keccak256(
      abi.encode(
        ALLOCATE,
        _shareholders,
        _amounts,
        _kycUntil)
    );
  }

  /**
   * @dev tokenize shares
   */
  function tokenizeShares(
    CMTAShareDistribution _shareDistribution,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV) public
    thresholdRequired(address(this), 0,
      abi.encodePacked(tokenizeHash(_shareDistribution)),
      0, threshold, _sigR, _sigS, _sigV)
  {
    require(_shareDistribution.owner() == address(this), "CMTABS01");

    CMTAPocToken newToken = _shareDistribution.token();
    require(newToken.owner() == address(this), "CMTABS02");

    updateReplayProtection();

    token = newToken;
    distribution = _shareDistribution;
    emit ShareTokenization(_shareDistribution);
  }

  /**
   * @dev validate KYC and allocate shares
   */
  function allocateAndKYCMany(
    address[] _shareholders,
    uint256[] _amounts,
    uint256 _kycUntil,
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV) public
    thresholdRequired(address(this), 0,
      abi.encodePacked(allocateHash(_shareholders, _amounts, _kycUntil)),
      0, threshold, _sigR, _sigS, _sigV)
  {
    updateReplayProtection();

    require(
      distribution.allocateManyShares(_shareholders, _amounts),
      "CMTABS03");
    token.validateManyKYCUntil(_shareholders, _kycUntil);
  }

  event ShareTokenization(CMTAShareDistribution distribution);
}
