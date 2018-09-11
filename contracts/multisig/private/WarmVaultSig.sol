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
 */
contract WarmVaultSig is DelegateSig, VaultSig {
  using SafeMath for uint256;

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

  bool public allowancesDefined;

  // For ETH, token's address is 0
  mapping(address => Allowance) internal allowances;

  modifier ifAllowancesDefined() {
    require(allowancesDefined);
    _;
  }

  constructor(
    address[] _addresses, uint8 _threshold)
    public VaultSig(_addresses, _threshold) 
  { }

  function allowancesDefined() public view returns (bool) {
    return allowancesDefined;
  }

  function ethAllowanceLimit()
    public view returns (uint256)
  {
    return allowances[address(0)].spendingLimit;
  }

  function ethAllowanceRate()
    public view returns (uint256)
  {
    return allowances[address(0)].spendingRate;
  }

  function ethAllowanceAtOnceLimit()
    public view returns (uint256)
  {
    return allowanceAtOnceLimit(address(0));
  }

  function ethAllowanceLastSpentAt()
    public view returns (uint256)
  {
    return allowanceLastSpentAt(address(0));
  }

  function ethAllowanceRemaining()
    public view returns (uint256)
  {
    return allowanceRemaining(address(0));
  }

  function allowanceLimit(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingLimit;
  }

  function allowanceRate(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingRate;
  }

  function allowanceAtOnceLimit(address _token)
    public view returns (uint256)
  {
    return allowances[_token].spendingAtOnceLimit;
  }

  function allowanceLastSpentAt(address _token)
    public view returns (uint256)
  {
    return allowances[_token].lastSpentAt;
  }

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
      require(_value == 0);
      require(readSelector(_data) == ERC20_TRANSFER_SELECTOR);
     
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
  ) public thresholdRequired(threshold, _sigR, _sigS, _sigV)
    returns (bool)
  {
    require(!allowancesDefined);
    require(_spendingLimit != 0);
    require(_spendingAtOnceLimit != 0);
    require(allowances[_token].spendingLimit == 0);

    allowances[_token] = Allowance(
      _spendingLimit,
      _spendingRate,
      _spendingAtOnceLimit,
      _spendingLimit,
      0
    );
    return true;
  }

  /**
   * @dev end allowances defintion
   */
  function endAllowancesDefinition(
    bytes32[] _sigR, bytes32[] _sigS, uint8[] _sigV)
    thresholdRequired(threshold, _sigR, _sigS, _sigV)
    public
  {
    require(!allowancesDefined);
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
    require(_value <= remaining);

    Allowance storage allowance = allowances[_token];
    require(_value <= allowance.spendingAtOnceLimit);
    allowance.remaining = remaining.sub(_value);
    allowance.lastSpentAt = currentTime();
  }
}
