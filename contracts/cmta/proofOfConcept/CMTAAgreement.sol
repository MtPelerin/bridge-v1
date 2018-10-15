pragma solidity ^0.4.24;

import "../../zeppelin/ownership/Ownable.sol";


/**
 * @title CMTAAgreement
 * @dev CMTAAgreement contract
 *
 * This contract provide a hash corresponding to the legal user agreement
 * and a user acceptance mecanism.
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
 * @notice Swissquote Bank SA solely is entitled to the GNU LGPL.
 * @notice Any other party is subject to the copyright mentioned in the software.
 *
 * Error messages
 * CMTAA01: Holder must accept the agreement
 * CMTAA02: Only the current agreement may be accepted
 */
contract CMTAAgreement is Ownable {

  bytes32 public agreementHash;
  mapping(address => bytes32) private agreements;

  /**
   * @dev constructor function
   */
  constructor(bytes32 _agreementHash) public
  {
    updateAgreement(_agreementHash);
  }

  /**
   * @dev Modifier to make a function callable only when the sender Kyc is still valid.
   */
  modifier whenAgreementAccepted(address _holder) {
    require(
      agreementHash == 0 || agreements[_holder] == agreementHash,
      "CMTAA01");
    _;
  }

  /**
   * @dev isAgreementAccepted
   */
  function isAgreementAccepted(address _holder)
    public view returns (bool)
  {
    return agreements[_holder] == agreementHash;
  }

  /**
   * @dev update agreement
   */
  function updateAgreement(bytes32 _agreementHash)
    public onlyOwner returns (bool)
  {
    agreementHash = _agreementHash;
    agreements[msg.sender] = _agreementHash;
    return true;
  }

  /**
   * @dev accept agreement
   */
  function acceptAgreement(bytes32 _agreementHash)
    public returns (bool)
  {
    require(agreementHash == _agreementHash, "CMTAA02");
    agreements[msg.sender] = _agreementHash;
    return true;
  }
}
