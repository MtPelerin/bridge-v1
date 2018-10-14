pragma solidity ^0.4.24;

import "../../zeppelin/ownership/Ownable.sol";
import "../../zeppelin/token/ERC20/StandardToken.sol";
import "../../zeppelin/math/SafeMath.sol";


/**
 * @title SplitableToken
 * @dev BasicToken contract which implement a split supply mechanims
 * @dev WARNING: Apart from the BasicToken class, the balances attribute should
 * @dev WARNING: never be used directly. balanceOf() method should always be used
 * @dev WARNING: instead!
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
 * E01: split ratio must be non null
 */
contract SplitableToken is StandardToken, Ownable {
  using SafeMath for uint256;

  uint256 constant SPLIT_RATIO_PRECISION = 10**9;
  uint256 public cumulatedSplitRatio = SPLIT_RATIO_PRECISION;
  mapping(address => uint256) private lastEvalSplitRatios;

  // Overflow on attributes below is an expected behavior
  // The contract should not be locked because
  // the max uint256 value is reached
  // Usage of this value must handle the overflow
  uint256 public allTimeSplited = 0; // potential overflow

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    if (lastEvalSplitRatios[_owner] == cumulatedSplitRatio) {
      return balances[_owner];
    }
    return balances[_owner].mul(
      cumulatedSplitRatio).div(lastEvalSplitRatios[_owner]);
  }

  /**
   * @dev ERC20 transfer
   */
  function transfer(address _to, uint256 _value) public
    returns (bool)
  {
    evalSplitRatio(msg.sender);
    evalSplitRatio(_to);
    return super.transfer(_to, _value);
  }

  /**
   * @dev ERC20 transferFrom
   */
  function transferFrom(address _from, address _to, uint256 _value) public
    returns (bool)
  {
    evalSplitRatio(_from);
    evalSplitRatio(_to);
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev called by the owner to split the token
   */
  function split(uint256 _splitRatio) public onlyOwner returns (bool) {
    require(_splitRatio != 0, "E01");
    allTimeSplited ++;
    totalSupply_ = totalSupply_.mul(_splitRatio);
    cumulatedSplitRatio = cumulatedSplitRatio.mul(_splitRatio);
    emit Split(totalSupply_, _splitRatio);
    return true;
  }

  /**
   * @dev evalSplitRatio
   **/
  function evalSplitRatio(address _holder) private {
    if (lastEvalSplitRatios[_holder] != cumulatedSplitRatio) {
      balances[_holder] = balances[_holder].mul(
        cumulatedSplitRatio).div(lastEvalSplitRatios[_holder]);
      lastEvalSplitRatios[_holder] = cumulatedSplitRatio;
    }
  }

  event Split(uint256 newSupply, uint256 splitRatio);
}
