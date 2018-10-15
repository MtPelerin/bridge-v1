pragma solidity ^0.4.24;

import "./PublicMultiSig.sol";


/**
 * @title PublicMultiSigWithRBAC
 * @dev PublicMultiSigWithRBAC contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * PMSWR01: msg.sender is not a suggester
 * PMSWR02: msg.sender is not an approver
 * PMSWR03: msg.sender is not an executer
 */
contract PublicMultiSigWithRBAC is PublicMultiSig {

  struct ParticipantRBAC {
    bool suggester;
    bool approver;
    bool executer;
  }
  mapping(address => ParticipantRBAC) internal participantRBACs;

  /**
   * @dev Modifier for suggester only
   */
  modifier onlySuggester() {
    require(participantRBACs[msg.sender].suggester, "PMSWR01");
    _;
  }

  /**
   * @dev Modifier for approver only
   */
  modifier onlyApprover() {
    require(participantRBACs[msg.sender].approver, "PMSWR02");
    _;
  }

  /**
   * @dev Modifier for executer only
   */
  modifier onlyExecuter() {
    require(participantRBACs[msg.sender].executer, "PMSWR03");
    _;
  }

  /**
   * @dev contructor
   **/
  constructor(
    uint256 _threshold,
    uint256 _duration,
    address[] _participants,
    uint256[] _weights,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers)
    public PublicMultiSig(_threshold, _duration, _participants, _weights)
  {
    updateManyParticipantsRolesInternal(
      _participants,
      _suggesters,
      _approvers,
      _executers
    );
  }

  /**
   * @dev is the participant a suggeester
   */
  function isSuggester(address _address)
    public view returns (bool)
  {
    return participantRBACs[_address].suggester;
  }

  /**
   * @dev is the participant an approver
   */
  function isApprover(address _address) public view returns (bool) {
    return participantRBACs[_address].approver;
  }

  /**
   * @dev is the participant an executer
   */
  function isExecuter(address _address) public view returns (bool) {
    return participantRBACs[_address].executer;
  }

  /**
   * @dev execute the transaction
   */
  function execute(uint256 _transactionId) public onlyExecuter returns (bool) {
    return super.execute(_transactionId);
  }

  /**
   * @dev suggest a new transaction
   */
  function suggest(
    address _destination,
    uint256 _value,
    bytes _data) public onlySuggester returns (bool)
  {
    return super.suggest(_destination, _value, _data);
  }

  /**
   * @dev approve a transaction
   */
  function approve(
    uint256 _transactionId) public onlyApprover returns (bool)
  {
    return super.approve(_transactionId);
  }

  /**
   * @dev revoke a transaction approval
   */
  function revokeApproval(
    uint256 _transactionId) public onlyApprover returns (bool)
  {
    return super.revokeApproval(_transactionId);
  }

  /**
   * @dev add a participant
   * Participant role will be defaulted to approver
   * It is defined for compatibility reason with parent contract
   */
  function addParticipant(
    address _participant,
    uint256 _weight) public onlyOwner returns (bool)
  {
    return addParticipantWithRoles(
      _participant,
      _weight,
      false,
      true,
      false
    );
  }

  /**
   * @dev add many participants
   * Participants role will be defaulted to approver
   * It is defined for compatibility reason with parent contract
   */
  function addManyParticipants(
    address[] _participants,
    uint256[] _weights) public onlyOwner returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      addParticipantWithRoles(
        _participants[i],
        _weights[i],
        false,
        true,
        false
      );
    }
    return true;
  }

  /**
   * @dev add participants with roles
   */
  function addParticipantWithRoles(
    address _participant,
    uint256 _weight,
    bool _suggester,
    bool _approver,
    bool _executer) public onlyOwner returns (bool)
  {
    super.addParticipant(_participant, _weight);
    updateParticipantRolesInternal(
      _participant,
      _suggester,
      _approver,
      _executer
    );
    return true;
  }

  /**
   * @dev add many participants with roles
   */
  function addManyParticipantsWithRoles(
    address[] _participants,
    uint256[] _weights,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers) public onlyOwner returns (bool)
  {
    super.addManyParticipants(_participants, _weights);
    updateManyParticipantsRoles(
      _participants,
      _suggesters,
      _approvers,
      _executers
    );
    return true;
  }

  /**
   *  @dev update participant roles
   **/
  function updateParticipantRoles(
    address _participant,
    bool _suggester,
    bool _approver,
    bool _executer) public onlyOwner returns (bool)
  {
    return updateParticipantRolesInternal(
      _participant,
      _suggester,
      _approver,
      _executer
    );
  }

  /**
   * @dev update many participants roles
   */
  function updateManyParticipantsRoles(
    address[] _participants,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers) public onlyOwner returns (bool)
  {
    return updateManyParticipantsRolesInternal(
      _participants,
      _suggesters,
      _approvers,
      _executers
    );
  }

  /**
   *  @dev update participant roles internal
   **/
  function updateParticipantRolesInternal(
    address _participant, 
    bool _suggester,
    bool _approver,
    bool _executer) internal returns (bool)
  {
    ParticipantRBAC storage participantRBAC = participantRBACs[_participant];
    participantRBAC.suggester = _suggester;
    participantRBAC.approver = _approver;
    participantRBAC.executer = _executer;
    
    emit ParticipantRolesUpdated(
      _participant,
      _suggester,
      _approver,
      _executer
    );
    return true;
  }

  /**
   * @dev update many participants role internals
   */
  function updateManyParticipantsRolesInternal(
    address[] _participants,
    bool[] _suggesters,
    bool[] _approvers,
    bool[] _executers) internal returns (bool)
  {
    for (uint256 i = 0; i < _participants.length; i++) {
      updateParticipantRolesInternal(
        _participants[i],
        _suggesters[i],
        _approvers[i],
        _executers[i]
      );
    }
    return true;
  }

  event ParticipantRolesUpdated(
    address indexed participant,
    bool _suggester,
    bool _approver,
    bool _executer
  );
}
