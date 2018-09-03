pragma solidity ^0.4.24;

import "./MultiSig.sol";


/**
 * @title DelegateSig
 * @dev DelegateSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * The configuration is to be done in children
 * The following instruction allows to do it
 * grants[contract][bytes4(keccak256(signature)] = Grant([], 1);
 *
 * Error messages
 */
contract DelegateSig is MultiSig {

  // destination x method => Grant
  mapping(address => mapping(bytes4 => Grant)) grants;
  struct Grant {
    address[] delegates;
    uint8 threshold;
  }

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
        method) >= grants[_destination][method].threshold
    );
    _;
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
    address _destination, bytes4 _method)
    public view returns (uint256)
  {
    Grant storage grant = grants[_destination][_method];
    return (reviewSignaturesInternal(
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
  {
    require(grantsDefined);
    executeInternal(_destination, _value, _data);
  }

  /**
   * @dev add a grant (delegates, threshold) to an operation
   */
  function addGrant(
    address _destination, bytes4 _method,
    address[] _delegates, uint8 _threshold)
    internal
  {
    require(!grantsDefined);
    grants[_destination][_method] = Grant(_delegates, _threshold);
  }

  /**
   * @dev lock grant definition
   * Definition will be fixed after to avoid any mismanipulation
   */
  function endDefinition() internal {
    require(!grantsDefined);
    grantsDefined = true;
  }
}
