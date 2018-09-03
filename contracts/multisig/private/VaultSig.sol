pragma solidity ^0.4.24;

import "../../zeppelin/token/ERC20/ERC20.sol";
import "./LockableSig.sol";


/**
 * @title VaultSig
 * @dev VaultSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * The vault restrict operation to ETH or ERC20 transfer only
 *
 * Error messages
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
  function () payable public {
    require(msg.data.length == 0);
  }

  /**
   * @dev execute the transaction
   */
  function execute(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination,
    uint256 _value,
    bytes _data)
    thresholdRequired(threshold, _sigR, _sigS, _sigV) public
  {
    if (_data.length == 0) {
      executeInternal(_destination, _value, "");
    } else {
      require(_value == 0);
      require(readSelector(_data) == ERC20_TRANSFER_SELECTOR);
      executeInternal(_destination, 0, _data);
    }
  }

  /**
   * @dev execute an ERC20 transfer
   */
  function transferERC20(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _token,
    address _destination,
    uint256 _value) public
  {
    execute(
      _sigR,
      _sigS,
      _sigV,
      _token,
      0,
      abi.encodeWithSelector(
        ERC20_TRANSFER_SELECTOR, _destination, _value
      )
    );
  }

  /**
   * @dev execute a transfer
   */
  function transfer(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination,
    uint256 _value) public
  {
    execute(
      _sigR,
      _sigS,
      _sigV,
      _destination,
      _value,
      ""
    );
  }
}
