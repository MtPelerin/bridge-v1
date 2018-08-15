pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/StandardToken.sol";
import "../zeppelin/lifecycle/Pausable.sol";
import "./KnowYourCustomer.sol";


/**
 * @title RestrictedToken
 * @dev RestrictedToken contract
 *
 * Token with restriction on transferability due to several rules:
 * - KnowYourCustomer
 * - Pausable
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract RestrictedToken is StandardToken, KnowYourCustomer, Pausable {

  /**
   * @dev ERC20 transfer
   */
  function transfer(address _to, uint256 _value) public
    whenKYCisValid(_to) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool)
  {
    return super.transfer(_to, _value);
  }

  /**
   * @dev ERC20 transferFrom
   */
  function transferFrom(address _from, address _to, uint256 _value) public
    whenKYCisValid(_from) whenKYCisValid(_to) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev ERC20 approve
   */
  function approve(address _spender, uint256 _value) public
    whenKYCisValid(_spender) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool)
  {
    return super.approve(_spender, _value);
  }

  /**
   * @dev ERC20 increaseApproval
   */
  function increaseApproval(address _spender, uint _addedValue) public
    whenKYCisValid(_spender) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  /**
   * @dev ERC20 decreaseApproval
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public
    whenKYCisValid(_spender) whenKYCisValid(msg.sender)
    whenNotPaused returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}
