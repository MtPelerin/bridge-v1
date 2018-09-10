pragma solidity ^0.4.24;


/**
 * @title MultiSig
 * @dev MultiSig contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: Valid signatures below threshold
 */
contract MultiSig {
  address[]  signers_;
  uint8 public threshold;

  bytes32 public replayProtection;
  uint256 public nonce;

  /**
   * @dev constructor
   */
  constructor(address[] _signers, uint8 _threshold) public {
    signers_ = _signers;
    threshold = _threshold;

    // Prevent first transaction of different contracts
    // to be replayed here
    updateReplayProtection();
  }

  /**
   * @dev fallback function
   */
  function () payable public { }

  /**
   * @dev read a function selector from a bytes field
   * @param _data contains the selector
   */
  function readSelector(bytes _data) public pure returns (bytes4) {
    bytes4 selector;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      selector := mload(add(_data, 0x20))
    }
    return selector;
  }

  /**
   * @dev read ERC20 destination
   * @param _data ERC20 transfert
   */
  function readERC20Destination(bytes _data) public pure returns (address) {
    address destination;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      destination := mload(add(_data, 0x24))
    }
    return destination;
  }

  /**
   * @dev read ERC20 value
   * @param _data contains the selector
   */
  function readERC20Value(bytes _data) public pure returns (uint256) {
    uint256 value;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      value := mload(add(_data, 0x44))
    }
    return value;
  }

  /**
   * @dev Modifier verifying that valid signatures are above _threshold
   */
  modifier thresholdRequired(
    uint256 _threshold,
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
  {
    require(reviewSignatures(_sigR, _sigS, _sigV) >= _threshold, "E01");
    _;
  }

  /**
   * @dev returns signers
   */
  function signers() public view returns (address[]) {
    return signers_;
  }

  /**
   * returns threshold
   */
  function threshold() public view returns (uint8) {
    return threshold;
  }

  /**
   * @dev returns replayProtection
   */
  function replayProtection() public view returns (bytes32) {
    return replayProtection;
  }

  /**
   * @dev returns nonce
   */
  function nonce() public view returns (uint256) {
    return nonce;
  }

  /**
   * @dev returns the number of valid signatures
   */
  function reviewSignatures(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    public view returns (uint256)
  {
    return reviewSignaturesInternal(
      signers_,
      _sigR,
      _sigS,
      _sigV
    );
  }

  /**
   * @dev recover the public address from the signatures
   **/
  function recoverAddress(bytes32 _r, bytes32 _s, uint8 _v)
    public view returns (address)
  {
    // When used in web.eth.sign, geth will prepend the hash
    bytes32 hash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", replayProtection));

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    uint8 v = (_v < 27) ? _v += 27: _v;

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      return address(0);
    } else {
      return ecrecover(
        hash,
        v,
        _r,
        _s
      );
    }
  }

  /**
   * @dev execute a transaction if enough signatures are valid
   **/
  function execute(
    bytes32[] _sigR,
    bytes32[] _sigS,
    uint8[] _sigV,
    address _destination, uint256 _value, bytes _data)
    thresholdRequired(threshold, _sigR, _sigS, _sigV)
    public returns (bool)
  {
    executeInternal(_destination, _value, _data);
    return true;
  }

  /**
   * @dev review signatures against a list of signers
   * Signatures must be provided in the same order as the list of signers
   * All provided signatures must be valid and correspond to one of the signers
   * returns the number of valid signatures
   * returns 0 if the inputs are inconsistent
   */
  function reviewSignaturesInternal(
    address[] _signers,
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    internal view returns (uint256)
  {
    uint256 length = _sigR.length;
    if (length == 0 || length > _signers.length || (
      _sigS.length != length || _sigV.length != length
    ))
    {
      return 0;
    }

    uint256 validSigs = 0;
    address recovered = recoverAddress(_sigR[0], _sigS[0], _sigV[0]);
    for (uint256 i = 0; i < _signers.length; i++) {
      if (_signers[i] == recovered) {
        validSigs++;
        if (validSigs < length) {
          recovered = recoverAddress(
            _sigR[validSigs],
            _sigS[validSigs],
            _sigV[validSigs]
          );
        } else {
          break;
        }
      }
    }

    if (validSigs != length) {
      return 0;
    }

    return validSigs;
  }

  /**
   * @dev execute a transaction
   **/
  function executeInternal(address _destination, uint256 _value, bytes _data)
    internal
  {
    updateReplayProtection();
    if (_data.length == 0) {
      _destination.transfer(_value);
    } else {
      // solium-disable-next-line security/no-call-value
      require(_destination.call.value(_value)(_data));
    }
    emit Execution(_destination, _value, _data);
  }

  /**
   * @dev update replay protection
   * contract address is used to prevent replay between different contracts
   * block hash is used to prevent replay between branches
   * nonce is used to prevent replay within the contract
   **/
  function updateReplayProtection() private {
    replayProtection = keccak256(
      abi.encodePacked(address(this), blockhash(block.number-1), nonce));
    nonce++;
  }

  event Execution(address to, uint256 value, bytes data);
}
