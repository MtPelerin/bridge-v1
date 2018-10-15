pragma solidity ^0.4.24;

import "../../zeppelin/token/ERC20/ERC20.sol";
import "./LockableSig.sol";


/**
 * @title VaultSig
 * @dev VaultSig contract
 * The vault restrict operation to ETH or ERC20 transfer only
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
 * VS01: no data is expected when transfer ETH
 * VS02: there should be no ETH provided when data is found
 * VS03: this contract only accept data for ERC20 transfer
 */
contract VaultSig is LockableSig {

  bytes4 constant ERC20_TRANSFER_SELECTOR = bytes4(
    keccak256("transfer(address,uint256)")
  );

  /**
   * @dev constructor
   */
  constructor(address[] _addresses, uint8 _threshold)
    public LockableSig(_addresses, _threshold)
  {
  }

  /**
   * @dev fallback function
   */
  function () public payable {
    require(msg.data.length == 0, "VS01");
  }

  /**
   * @dev execute the transaction
   */
  function execute(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination,
    uint256 _value,
    bytes _data,
    uint256 _validity)
    public
    stillValid(_validity)
    thresholdRequired(_destination, _value, _data, _validity,
      threshold, _sigR, _sigS, _sigV)
    returns (bool)
  {
    if (_data.length == 0) {
      executeInternal(_destination, _value, "");
    } else {
      require(_value == 0, "VS02");
      require(readSelector(_data) == ERC20_TRANSFER_SELECTOR, "VS03");
      executeInternal(_destination, 0, _data);
    }
    return true;
  }

  /**
   * @dev execute an ERC20 transfer
   */
  function transferERC20(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _token,
    address _destination,
    uint256 _value) public
    returns (bool)
  {
    return execute(
      _sigR,
      _sigS,
      _sigV,
      _token,
      0,
      abi.encodeWithSelector(
        ERC20_TRANSFER_SELECTOR, _destination, _value
      ),
      0
    );
  }

  /**
   * @dev execute a transfer
   */
  function transfer(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination,
    uint256 _value) public
    returns (bool)
  {
    return execute(
      _sigR,
      _sigS,
      _sigV,
      _destination,
      _value,
      "",
      0
    );
  }
}
