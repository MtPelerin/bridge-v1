pragma solidity ^0.4.24;


/**
 * @title IRegistry
 * @dev IRegistry interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IRegistry {
  function name() public view returns (string);
  function addressLength() public view returns (uint256);
  function addressById(uint256 id) public view returns (address);

  function addAddress(address value) public returns (uint256);
  function removeAddressById(uint256 id) public returns (address);
  function replaceAddressById(uint256 id, address value)
    public returns (address);

  event AddressAdded(uint256 id, address newValue);
  event AddressRemoved(uint256 id, address oldValue);
  event AddressReplaced(uint256 id, address newValue, address oldValue);
}
