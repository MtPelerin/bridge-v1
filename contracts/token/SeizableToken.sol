pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/token/ERC20/BasicToken.sol";
import "../zeppelin/math/SafeMath.sol";
import "../interface/ISeizable.sol";


/**
 * @title SeizableToken
 * @dev BasicToken contract which allows owner to seize accounts
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: Owner cannot seize itself
*/
contract SeizableToken is BasicToken, Ownable, ISeizable {
  using SafeMath for uint256;

  // Overflow on attributes below is an expected behavior
  // The contract should not be locked because
  // the max uint256 value is reached
  // Usage of these value must handle the overflow
  uint256 public allTimeSeized = 0; // overflow may happend

  /**
   * @dev called by the owner to seize value from the account
   */
  function seize(address _account, uint256 _value) public onlyOwner {
    require(_account != owner, "E01");

    balances[_account] = balances[_account].sub(_value);
    balances[owner] = balances[owner].add(_value);

    allTimeSeized += _value;
    emit Seized(_account, _value);
  }

  event Seized(address account, uint256 amount);

}
