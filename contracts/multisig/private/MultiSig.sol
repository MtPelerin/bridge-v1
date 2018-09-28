pragma solidity ^0.4.24;


/**
 * @title MultiSig
 * @dev MultiSig contract
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
 * E01: Valid signatures below threshold
 * E02: Transaction validity has expired
 * E03: Sender does not belong to signers
 * E04: Execution should be correct
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
  function () public payable { }

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
    address _destination, uint256 _value, bytes _data,
    uint256 _validity, uint256 _threshold,
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
  {
    require(
      reviewSignatures(
        _destination, _value, _data, _validity, _sigR, _sigS, _sigV
      ) >= _threshold,
      "E01"
    );
    _;
  }

  /**
   * @dev Modifier verifying that transaction is still valid
   * @dev This modifier also protects against replay on forked chain.
   *
   * @notice If both the _validity and gasPrice are low, then there is a risk
   * @notice that the transaction is executed after its _validity but before it does timeout
   * @notice In that case, the transaction will fail.
   * @notice In general, it is recommended to use a _validity greater than the potential timeout
   */
  modifier stillValid(uint256 _validity)
  {
    if (_validity != 0) {
      require(_validity >= block.number, "E02");
    }
    _;
  }

  /**
   * @dev Modifier requiring that the message sender belongs to the signers
   */
  modifier onlySigners() {
    bool found = false;
    for(uint256 i=0; i < signers_.length && !found; i++) {
      found = (msg.sender == signers_[i]);
    }
    require(found, "E03");
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
    address _destination, uint256 _value, bytes _data,
    uint256 _validity,
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    public view returns (uint256)
  {
    return reviewSignaturesInternal(
      _destination,
      _value,
      _data,
      _validity,
      signers_,
      _sigR,
      _sigS,
      _sigV
    );
  }

  /**
   * @dev buildHash
   **/
  function buildHash(
    address _destination, uint256 _value,
    bytes _data, uint256 _validity)
    public view returns (bytes32)
  {
    // FIXME: web3/solidity behaves differently with empty bytes
    if (_data.length == 0) {
      return keccak256(
        abi.encode(
          _destination, _value, _validity, replayProtection
        )
      );
    } else {
      return keccak256(
        abi.encode(
          _destination, _value, _data, _validity, replayProtection
        )
      );
    }
  }

  /**
   * @dev recover the public address from the signatures
   **/
  function recoverAddress(
    address _destination, uint256 _value,
    bytes _data, uint256 _validity,
    bytes32 _r, bytes32 _s, uint8 _v)
    public view returns (address)
  {
    // When used in web.eth.sign, geth will prepend the hash
    bytes32 hash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32",
        buildHash(
          _destination,
          _value,
          _data,
          _validity
        )
      )
    );

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
    address _destination, uint256 _value, bytes _data, uint256 _validity)
    public
    stillValid(_validity)
    thresholdRequired(_destination, _value, _data, _validity, threshold, _sigR, _sigS, _sigV)
    returns (bool)
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
    address _destination, uint256 _value, bytes _data, uint256 _validity,
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
    address recovered = recoverAddress(
      _destination, _value, _data, _validity, 
      _sigR[0], _sigS[0], _sigV[0]);
    for (uint256 i = 0; i < _signers.length; i++) {
      if (_signers[i] == recovered) {
        validSigs++;
        if (validSigs < length) {
          recovered = recoverAddress(
            _destination,
            _value,
            _data,
            _validity,
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
      require(_destination.call.value(_value)(_data), "E04");
    }
    emit Execution(_destination, _value, _data);
  }

  /**
   * @dev update replay protection
   * contract address is used to prevent replay between different contracts
   * block hash is used to prevent replay between branches
   * nonce is used to prevent replay within the contract
   **/
  function updateReplayProtection() internal {
    replayProtection = keccak256(
      abi.encodePacked(address(this), blockhash(block.number-1), nonce));
    nonce++;
  }

  event Execution(address to, uint256 value, bytes data);
}
