pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20/BasicToken.sol";
import "../zeppelin/math/SafeMath.sol";
import "../interface/IIssuable.sol";


/**
 * @title IssuableToken
 * @dev BasicToken contract which implement an issuing mechanism.
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract IssuableToken is BasicToken, Ownable, IIssuable {
  using SafeMath for uint256;

  // Overflow on attributes below is an expected behavior
  // The contract should not be locked because
  // the max uint256 value is reached
  // Usage of these value must handle the overflow
  uint256 public allTimeIssued = 0; // potential overflow
  uint256 public allTimeRedeemed = 0; // potential overflow

  /**
   * @dev called by the owner to increase the supply
   */
  function issue(uint256 _amount) public onlyOwner {
    balances[owner] = balances[owner].add(_amount);
    totalSupply_ = totalSupply_.add(_amount);

    allTimeIssued += _amount;
    emit Issued(_amount);
  }

  /**
   * @dev called by the owner to decrease the supply
   */
  function redeem(uint256 _amount) public onlyOwner {
    balances[owner] = balances[owner].sub(_amount);
    totalSupply_ = totalSupply_.sub(_amount);

    allTimeRedeemed += _amount;
    emit Redeemed(_amount);
  }

  event Issued(uint256 amount);
  event Redeemed(uint256 amount);
}
