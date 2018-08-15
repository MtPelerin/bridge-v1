pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";


/**
 * @title KnowYourCustomer
 * @dev KnowYourCustomer contract
 * @dev Base contract which allows children to rely on a Know Your Customer mecanism.
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: User KYC is not valid anymore
 */
contract KnowYourCustomer is Ownable {

  mapping(address => uint256) validUntil_;

  /**
   * @dev Modifier to make a function callable only when the sender Kyc is still valid.
   */
  modifier whenKYCisValid(address _holder) {
    require(
      validUntil_[_holder] > currentTime() || _holder == owner,
      "E01");
    _;
  }

  /**
   * @dev function returns if the kyc is valid
   */
  function isKYCValid(address _address) public view returns (bool) {
    return (validUntil_[_address] > currentTime() || _address == owner);
  }

  /**
   * @dev function returns the KYC validity end date
   */
  function validUntil(address _address) public view returns (uint256) {
    return validUntil_[_address];
  }

  /**
   * @dev called by the owner to validate the KYC of an address until a certain date
   */
  function validateKYCUntil(
    address _address,
    uint256 _timestamp) public onlyOwner
  {
    validUntil_[_address] = _timestamp;
  }

  /**
   * @dev called by the owner to validate the KYC of an address until a certain date
   */
  function validateManyKYCUntil(
    address[] _addresses,
    uint256 _timestamp) public onlyOwner
  {
    for (uint256 i = 0; i < _addresses.length; i++) {
      validUntil_[_addresses[i]] = _timestamp;
    }
  }

  /**
   * @dev currentTime
   */
  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }
}
