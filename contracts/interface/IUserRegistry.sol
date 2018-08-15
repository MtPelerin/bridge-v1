pragma solidity ^0.4.24;


/**
 * @title IUserRegistry
 * @dev IUserRegistry interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 **/
contract IUserRegistry {

  function registerManyUsers(address[] _addresses, uint256 _validUntilTime)
    external;

  function attachManyAddresses(uint256[] _userIds, address[] _addresses)
    external;

  function detachManyAddresses(address[] _addresses)
    external;

  function userCount() public view returns (uint256);
  function userId(address _address) public view returns (uint256);
  function validUntilTime(uint256 _userId) public view returns (uint256);
  function locked(uint256 _userId) public view returns (bool);
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256);

  function isAddressValid(address _address) public view returns (bool);
  function isValid(uint256 _userId) public view returns (bool);

  function registerUser(address _address, uint256 _validUntilTime) public;
  function attachAddress(uint256 _userId, address _address) public;
  function detachAddress(address _address) public;
  function lockUser(uint256 _userId) public;
  function unlockUser(uint256 _userId) public;
  function lockManyUsers(uint256[] _userIds) public;
  function unlockManyUsers(uint256[] _userIds) public;
  function updateUser(uint256 _userId, uint256 _validUntil, bool _locked)
    public;

  function updateManyUsers(
    uint256[] _userIds,
    uint256 _validUntil,
    bool _locked) public;

  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public;

  function updateManyUsersExtended(
    uint256[] _userIds,
    uint256 _key,
    uint256 _value) public;
}
