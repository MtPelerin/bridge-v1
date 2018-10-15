pragma solidity ^0.4.24;

import "./MultiSig.sol";


/**
 * @title DelegateSig
 * @dev DelegateSig contract
 * The configuration is to be done in children
 * The following instruction allows to do it
 * addGrantInternal(contract, bytes4(keccak256(signature), [], 1);
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * DS01: Valid signatures must reach threshold
 * DS02: A grant must be defined
 * DS03: No grants must be defined
 * DS04: Enought delegates must be defined to reach threshold
 */
contract DelegateSig is MultiSig {
  bytes32 public constant GRANT = keccak256("GRANT");

  // destination x method => Grant
  mapping(address => mapping(bytes4 => Grant)) grants;
  struct Grant {
    address[] delegates;
    uint8 threshold;
  }
  bytes32 public grantsHash = GRANT;
  bool public grantsDefined;

  /**
   * @dev check that the signatures reach the threshold for a specific operations
   */
  modifier onlyDelegates(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination, bytes _data)
  {
    bytes4 method = readSelector(_data);
    require(
      reviewDelegateSigs(
        _sigR,
        _sigS,
        _sigV,
        _destination,
        _data,
        method
      ) >= grants[_destination][method].threshold,
      "DS01"
    );
    _;
  }

  /**
   * @dev return the hash of the grants configuration
   */
  function grantsHash() public view returns (bytes32) {
    return grantsHash;
  }

  /**
   * @dev check that grants has been defined
   */
  function grantsDefined() public view returns (bool) {
    return grantsDefined;
  }

  /**
   * @dev returns the deletages of a specific operations
   */
  function grantDelegates(address _destination, bytes4 _method)
    public view returns (address[])
  {
    return grants[_destination][_method].delegates;
  }

  /**
   * @dev returns the threshold for a specific operations
   */
  function grantThreshold(address _destination, bytes4 _method)
    public view returns (uint8)
  {
    return grants[_destination][_method].threshold;
  }

  /**
   * @dev returns the number of valid signatures for an operation
   */
  function reviewDelegateSigs(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination, bytes _data, bytes4 _method)
    public view returns (uint256)
  {
    Grant storage grant = grants[_destination][_method];
    return (reviewSignaturesInternal(
      _destination,
      0,
      _data,
      0,
      grant.delegates,
      _sigR,
      _sigS,
      _sigV)
    );
  }

  /**
   * @dev execute on behalf signers as delegates
   */
  function executeOnBehalf(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination, uint256 _value, bytes _data) public
    onlyDelegates(_sigR, _sigS, _sigV, _destination, _data)
    returns (bool)
  {
    require(grantsDefined, "DS02");
    executeInternal(_destination, _value, _data);
    return true;
  }

  /**
   * @dev add a grant (delegates, threshold) to an operation
   * @dev same signatures of signers may be reused for all call to addGrant
   * @dev as the approval of grants, ie 'endDefinition()', requires signers
   * @dev to approve the grants hash
   */
  function addGrant(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination, bytes4 _method,
    address[] _delegates, uint8 _grantThreshold)
    public
    thresholdRequired(address(this), 0,
      abi.encodePacked(GRANT), 0,
      threshold, _sigR, _sigS, _sigV)
    returns (bool)
  {
    require(!grantsDefined, "DS03");
    require(_delegates.length >= _grantThreshold, "DS04");
    grants[_destination][_method] = Grant(_delegates, _grantThreshold);
    grantsHash = keccak256(
      abi.encode(
        grantsHash,
        _destination,
        _method,
        _delegates,
        _grantThreshold
      )
    );
    return true;
  }

  /**
   * @dev lock grant definition
   * Definition will be fixed after to avoid any mismanipulation
   */
  function endDefinition(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    public
    thresholdRequired(address(this), 0,
      abi.encodePacked(grantsHash), // conversion from Bytes32 to Bytes
      0, threshold, _sigR, _sigS, _sigV)
    returns (bool)
  {
    require(!grantsDefined, "DS03");
    updateReplayProtection();
    grantsDefined = true;
    return true;
  }
}
