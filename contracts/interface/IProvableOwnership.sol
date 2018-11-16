pragma solidity ^0.4.24;


/**
 * @title IProvableOwnership
 * @dev IProvableOwnership interface which describe proof of ownership.
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 **/
contract IProvableOwnership {
  function proofLength(address _holder) public view returns (uint256);
  function proofAmount(address _holder, uint256 _proofId)
    public view returns (uint256);

  function proofDateFrom(address _holder, uint256 _proofId)
    public view returns (uint256);

  function proofDateTo(address _holder, uint256 _proofId)
    public view returns (uint256);

  function createProof(address _holder) public;
  function checkProof(address _holder, uint256 _proofId, uint256 _at)
    public view returns (uint256);

  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
    ) public returns (bool);

  function transferFromWithProofs(
    address _from,
    address _to,
    uint256 _value,
    bool _proofFrom,
    bool _proofTo
    ) public returns (bool);

  event ProofOfOwnership(address indexed holder, uint256 proofId);
}
