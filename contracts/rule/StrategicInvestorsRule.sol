pragma solidity ^0.4.24;

import "../interface/IRule.sol";
import "../interface/IUserRegistry.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";


/**
 * @title StrategicInvestorsRule
 * @dev StrategicInvestorsRule interface
 * The rule check if the holder is going to reach the shares ownership level
 * where he does become a strategic investors.
 * In this case, he must become registred before
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract StrategicInvestorsRule is IRule, Ownable {
  using SafeMath for uint256;

  IUserRegistry public userRegistry;
  ERC20 public token;

  // Number of token to hold to become a strategic investor
  uint256 public strategicThreshold;

  // Strategic investors whitelist
  mapping(uint256 => bool) internal strategicInvestors;

  /**
   * @dev constructor
   */
  constructor(IUserRegistry _userRegistry, ERC20 _token,
          uint256 _strategicThreshold, uint256[] _userIds) public {
    userRegistry = _userRegistry;
    token = _token;
    strategicThreshold = _strategicThreshold;
    updateManyStrategicInvestors(_userIds, true);
  }

  /**
   * @dev returns the user registry
   */
  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  /**
   * @dev returns the user registry
   */
  function token() public view returns (ERC20) {
    return token;
  }

  /**
   * @dev returns the strategic threshold
   */
  function strategicThreshold() public view returns (uint256) {
    return strategicThreshold;
  }

  /**
   * @dev does the user belongs to strategic investors
   */
  function isStrategicInvestor(uint256 _userId) public view returns (bool) {
    return strategicInvestors[_userId];
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    if (token.balanceOf(_address) >= strategicThreshold) {
      return strategicInvestors[userRegistry.userId(_address)];
    }
    return true;
  }

  /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address /* _from */, address _to, uint256 _amount)
    public view returns (bool)
  {
    if (token.balanceOf(_to).add(_amount) >= strategicThreshold) {
      return strategicInvestors[userRegistry.userId(_to)];
    }
    return true;
  }

  /**
   * @dev update the strategic investor status
   */
  function updateStrategicInvestor(uint256 _userId, bool _isStrategicInvestor)
    public onlyOwner
  {
    strategicInvestors[_userId] = _isStrategicInvestor;
    emit StrategicInvestorUpdated(_userId, _isStrategicInvestor);
  }

  /**
   * @dev update the strategic investor status
   */
  function updateManyStrategicInvestors(
    uint256[] _userIds,
    bool _isStrategicInvestor)
    public onlyOwner
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      strategicInvestors[_userIds[i]] = _isStrategicInvestor;
      emit StrategicInvestorUpdated(_userIds[i], _isStrategicInvestor);
    }
  }

  /**
   * @dev update the strategic threshold
   */
  function updateStrategicThreshold(uint256 _strategicThreshold)
    public onlyOwner
  {
    strategicThreshold = _strategicThreshold;
    emit StrategicThresholdUpdated(strategicThreshold);
  }

  event StrategicThresholdUpdated(uint256 strategicThreshold);
  event StrategicInvestorUpdated(uint256 indexed userId, bool status);
}
