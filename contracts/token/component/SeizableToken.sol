pragma solidity ^0.4.24;

import "../../zeppelin/token/ERC20/BasicToken.sol";
import "../../zeppelin/math/SafeMath.sol";
import "../../interface/ISeizable.sol";
import "../../Authority.sol";


/**
 * @title SeizableToken
 * @dev BasicToken contract which allows owner to seize accounts
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * ST01: Owner cannot seize itself
*/
contract SeizableToken is BasicToken, Authority, ISeizable {
  using SafeMath for uint256;

  // Although very unlikely, the value below may overflow.
  // This contract and his childs should expect it to happened and consider
  // this value as only the first 256 bits of the complete value.
  uint256 public allTimeSeized = 0; // overflow may happend

  /**
   * @dev called by the owner to seize value from the account
   */
  function seize(address _account, uint256 _value)
    public onlyAuthority
  {
    require(_account != owner, "ST01");

    balances[_account] = balances[_account].sub(_value);
    balances[authority] = balances[authority].add(_value);

    allTimeSeized += _value;
    emit Seize(_account, _value);
  }
}
