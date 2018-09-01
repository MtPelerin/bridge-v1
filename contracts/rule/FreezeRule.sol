pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../Authority.sol";
import "../interface/IRule.sol";


/**
 * @title FreezeRule
 * @dev FreezeRule contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * This rule allow a legal authority to enforce a freeze of assets.
 *
 * Error messages
 * E01: The address is frozen
 */
contract FreezeRule is IRule, Authority {

  mapping(address => uint256) freezer;

  /**
   * @dev is address frozen
   */
  function isAddressFrozen(address _address) public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return freezer[_address] < now;
  }

  /**
   * @dev allow authority to freeze the address
   * @param _until allows to auto unlock if the frozen time is known initially.
   * otherwise infinity can be used
   */
  function freezeAddress(address _address, uint256 _until)
    public onlyAuthority("REGULATOR") returns (bool)
  {
    freezer[_address] = _until;
  }

  /**
   * @dev allow authority to freeze several addresses
   * @param _until allows to auto unlock if the frozen time is known initially.
   * otherwise infinity can be used
   */
  function freezeAddresses(address[] _addresses, uint256 _until)
    public onlyAuthority("REGULATOR") returns (bool)
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      freezer[_addresses[i]] = _until;
    }
  }

  /**
   * @dev validates an address
   */
  function isAddressValid(address _address) public view returns (bool) {
    return isAddressFrozen(_address);
  }

   /**
   * @dev validates a transfer of ownership
   */
  function isTransferValid(address _from, address _to, uint256 /* _amount */)
    public view returns (bool)
  {
    return isAddressFrozen(_from) && isAddressFrozen(_to);
  }
}
