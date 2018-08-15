pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../interface/IRule.sol";
import "../interface/IUserRegistry.sol";


/**
 * @title UserKycRule
 * @dev UserKycRule contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 *  UserRegistry with the implementation of IRule
 *
 * Error messages
 * E01: The owner of the address is not identified
 */
contract UserKycRule is IRule {

  IUserRegistry public userRegistry;

  /**
   * @dev constructor
   **/
  constructor(IUserRegistry _userRegistry) public {
    userRegistry = _userRegistry;
  }

  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  /**
   * @dev Modifier requiring to make a function callable
   * onlywhen the user KYC is valid
   */
  modifier whenKYCisValid(address _address) {
    require(userRegistry.isAddressValid(_address), "E01");
    _;
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    return userRegistry.isAddressValid(_address);
  }

   /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return userRegistry.isAddressValid(_from) &&
      userRegistry.isAddressValid(_to);
  }
}
