pragma solidity ^0.4.24;

import "./IRule.sol";


/**
 * @title IWithRules
 * @dev IWithRules interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IWithRules {
  function ruleLength() public view returns (uint256);
  function rule(uint256 _ruleId) public view returns (IRule);
  function validateAddress(address _address) public view returns (bool);
  function validateTransfer(address _from, address _to, uint256 _amount)
    public view returns (bool);

  function addRule(IRule _rule) public;
  function addManyRules(IRule[] _rules) public;
  function removeRule(uint256 _ruleId) public;
}
