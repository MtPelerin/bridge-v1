pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../interface/IWithRules.sol";
import "../interface/IRule.sol";


/**
 * @title WithRules
 * @dev WithRules contract allows inheriting contract to use a set of validation rules
 * @dev contract owner may add or remove rules
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
 * E01: The address rules are not valid
 * E02: The transfer rules are not valid
 * E03: Rule must exist
 * E04: Rules must not be empty
 * E05: The rule does not exist
 **/
contract WithRules is IWithRules, Ownable {

  IRule[] internal rules;

  /**
   * @dev Constructor
   */
  constructor(IRule[] _rules) public {
    rules = _rules;
  }

  /**
   * @dev Returns the number of rules
   */
  function ruleLength() public view returns (uint256) {
    return rules.length;
  }

  /**
   * @dev Returns the Rule associated to the specified ruleId
   */
  function rule(uint256 _ruleId) public view returns (IRule) {
    return rules[_ruleId];
  }

  /**
   * @dev Check if the rules are valid for an address
   */
  function validateAddress(address _address) public view returns (bool) {
    for (uint256 i = 0; i < rules.length; i++) {
      if (!rules[i].isAddressValid(_address)) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Check if the rules are valid
   */
  function validateTransfer(address _from, address _to, uint256 _amount)
    public view returns (bool)
  {
    for (uint256 i = 0; i < rules.length; i++) {
      if (!rules[i].isTransferValid(_from, _to, _amount)) {
        return false;
      }
    }
    return true;
  }

  /**
   * @dev Modifier to make functions callable
   * only when participants follow rules
   */
  modifier whenAddressRulesAreValid(address _address) {
    require(validateAddress(_address), "E01");
    _;
  }

  /**
   * @dev Modifier to make transfer functions callable
   * only when participants follow rules
   */
  modifier whenTransferRulesAreValid(
    address _from,
    address _to,
    uint256 _amount)
  {
    require(validateTransfer(_from, _to, _amount), "E02");
    _;
  }

  /**
   * @dev Add a rule to the token
   */
  function addRule(IRule _rule) public onlyOwner {
    require(address(_rule) != address(0), "E03");
    rules.push(_rule);
    emit RuleAdded(rules.length-1);
  }

  /**
   * @dev Add rules to the token
   */
  function addManyRules(IRule[] _rules) public onlyOwner {
    require(_rules.length > 0, "E04");
    for (uint256 i = 0; i < _rules.length; i++) {
      require(address(_rules[i]) != address(0), "E03");
      addRule(_rules[i]);
    }
  }

  /**
   * @dev Remove a rule from the token
   */
  function removeRule(uint256 _ruleId) public onlyOwner {
    require(_ruleId < rules.length, "E05");

    delete rules[_ruleId];
    if (_ruleId != rules.length-1) {
      rules[_ruleId] = rules[rules.length-1];
    }
    rules.length--;
    emit RuleRemoved(_ruleId);
  }

  event RuleAdded(uint256 ruleId);
  event RuleRemoved(uint256 ruleId);
}
