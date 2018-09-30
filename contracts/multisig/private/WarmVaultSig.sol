pragma solidity ^0.4.24;

import "../../zeppelin/math/SafeMath.sol";
import "./VaultSig.sol";
import "./DelegateSig.sol";


/**
 * @title WarmVaultSig
 * @dev WarmVaultSig contract
 * This contract defines allowances on delegates.
 * Delegates can spend up to a limit of ETH or ERC20.
 * Gradually over time, the ability to respend recover.
 * Delegates also have a per transfer amount limit.
 * The signers have the same restrictions as the VaultSig contract.
 * Hence, they don't have allowance restrictions.
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
 * E01: Allowances must be defined
 * E02: No values is expected when data is provided
 * E03: Only ERC20 operation are accepted in this contract
 * E04: Allowances must not be defined
 * E05: The spending limit must not be 0
 * E06: The spending limit at once must not be 0
 * E07: The token allowance must not be defined
 * E08: There is not enough allowance remaining
 * E09: Too much is being spent at once
 */
contract WarmVaultSig is DelegateSig, VaultSig {
  using SafeMath for uint256;

  bytes32 public constant ALLOWANCE = keccak256("ALLOWANCE");
  uint256 public constant SPENDING_RATE_UNIT = 1 hours;

  struct Allowance {
    // Configuration
    // Allowance limit that can be spent
    uint256 spendingLimit;
    // Rate at which the allowance will be restored
    uint256 spendingRate; 
    // Limit of what can be spent in one transaction
    uint256 spendingAtOnceLimit;
     
    // State
    uint256 remaining;
    uint256 lastSpentAt;
  }

  bytes32 public allowancesHash = ALLOWANCE;
  bool public allowancesDefined;

  // For ETH, token's address is 0
  mapping(address => Allowance) internal allowances;

  modifier ifAllowancesDefined() {
    require(allowancesDefined, "E01");
    _;
  }

  /**
   * @dev constructor
   */
  constructor(
    address[] _addresses, uint8 _threshold)
    public VaultSig(_addresses, _threshold) 
  { }

  /**
   * @dev allowances hash
   */
  function allowancesHash() public view returns (bytes32) {
    return allowancesHash;
  }

  /**
   * @dev allowances defined
   */
  function allowancesDefined() public view returns (bool) {
    return allowancesDefined;
  }

  /**
   * @dev eth allowances limit
   */
  function ethAllowanceLimit()
    public view returns (uint256)
  {
    return allowances[address(0)].spendingLimit;
  }

  /**
   * @dev eth allowance rate
   */
  function ethAllowanceRate()
    public view returns (uint256)
  {
    return allowances[address(0)].spendingRate;
  }

  /**
   * @dev eth allowance at once limit
   */
  function ethAllowanceAtOnceLimit()
    public view returns (uint256)
  {
    return allowanceAtOnceLimit(address(0));
  }

  /**
   * @dev eth allowance last spent at
   */
  function ethAllowanceLastSpentAt()
    public view returns (uint256)
  {
    return allowanceLastSpentAt(address(0));
  }

  /**
   * @dev eth allowance remaining
   */
  function ethAllowanceRemaining()
    public view returns (uint256)
  {
    return allowanceRemaining(address(0));
  }

  /**
   * @dev allowance limit
   */
  function allowanceLimit(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingLimit;
  }

  /**
   * @dev allowance rate
   */
  function allowanceRate(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingRate;
  }

  /**
   * @dev allowance at once limit
   */
  function allowanceAtOnceLimit(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingAtOnceLimit;
  }

  /**
   * @dev allowance last spent at
   */
  function allowanceLastSpentAt(address _token)
    public view returns (uint256)
  {
    return allowances[_token].lastSpentAt;
  }

  /**
   * @dev allowance remaining
   */
  function allowanceRemaining(address _token)
    public view returns (uint256)
  {
    Allowance memory allowance = allowances[_token];
    uint256 restored = allowance.spendingRate.mul(
      currentTime().sub(allowance.lastSpentAt)
    );

    uint256 remaining = allowance.remaining.add(restored); 
    if (remaining < allowance.spendingLimit) {
      return remaining;
    }
    
    return allowance.spendingLimit;
  }

  /**
   * @dev execute on behalf
   */
  function executeOnBehalf(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination, uint256 _value, bytes _data)
    public returns (bool)
  {
    if (_data.length == 0) {
      return transferOnBehalf(
        _sigR, _sigS, _sigV,
        _destination, _value);
    } else {
      require(_value == 0, "E02");
      require(readSelector(_data) == ERC20_TRANSFER_SELECTOR, "E03");
     
      // scan data parameters
      address token = _destination;
      address destinationERC20 = readERC20Destination(_data);
      uint256 valueERC20 = readERC20Value(_data);

      return transferERC20OnBehalf(
        _sigR, _sigS, _sigV,
        token, destinationERC20, valueERC20);
    }
  }

  /**
   * @dev execute an ERC20 transfer
   */
  function transferERC20OnBehalf(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _token,
    address _destination,
    uint256 _value)
    public ifAllowancesDefined
    returns (bool)
  {
    evalAllowance(_token, _value);
    return super.executeOnBehalf(
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
  function transferOnBehalf(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _destination,
    uint256 _value)
    public ifAllowancesDefined
    returns (bool)
  {
    evalAllowance(address(0), _value);
    return super.executeOnBehalf(
      _sigR,
      _sigS,
      _sigV,
      _destination,
      _value,
      ""
    );
  }

  /**
   * @dev add allowance
   */
  function addEthAllowance(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    uint256 _spendingLimit,
    uint256 _spendingRate,
    uint256 _spendingAtOnceLimit
  ) public returns (bool)
  {
    return addAllowance(
      _sigR, _sigS, _sigV,
      address(0),
      _spendingLimit,
      _spendingRate,
      _spendingAtOnceLimit);
  }

   /**
   * @dev add allowance
   */
  function addAllowance(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV,
    address _token,
    uint256 _spendingLimit,
    uint256 _spendingRate,
    uint256 _spendingAtOnceLimit
  ) public
    thresholdRequired(address(this), 0,
      abi.encodePacked(ALLOWANCE), 0,
      threshold, _sigR, _sigS, _sigV)
    returns (bool)
  {
    require(!allowancesDefined, "E04");
    require(_spendingLimit != 0, "E05");
    require(_spendingAtOnceLimit != 0, "E06");
    require(allowances[_token].spendingLimit == 0, "E07");

    allowances[_token] = Allowance(
      _spendingLimit,
      _spendingRate,
      _spendingAtOnceLimit,
      _spendingLimit,
      0
    );
    allowancesHash = keccak256(
      abi.encode(
        allowancesHash,
        _token,
        _spendingLimit,
        _spendingRate,
        _spendingAtOnceLimit
      )
    );
    return true;
  }

  /**
   * @dev end allowances defintion
   */
  function endAllowancesDefinition(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    public
    thresholdRequired(address(this), 0,
    abi.encodePacked(allowancesHash), // conversion from Bytes32 to Bytes
    0, threshold, _sigR, _sigS, _sigV)
  {
    require(!allowancesDefined, "E04");
    updateReplayProtection();
    allowancesDefined = true;
  }

  /**
   * @dev return current time in the specific unit
   */
  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp.div(SPENDING_RATE_UNIT);
  }

  /**
   * @dev eval allowance
   */
  function evalAllowance(address _token, uint256 _value) private {
    uint256 remaining = allowanceRemaining(_token);
    require(_value <= remaining, "E08");

    Allowance storage allowance = allowances[_token];
    require(_value <= allowance.spendingAtOnceLimit, "E09");
    allowance.remaining = remaining.sub(_value);
    allowance.lastSpentAt = currentTime();
  }
}
