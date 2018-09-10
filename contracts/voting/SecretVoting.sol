pragma solidity ^0.4.24;

import "./Voting.sol";


/**
 * @title SecretVoting
 * @dev SecretVoting contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * This content cannot be used, copied or reproduced in part or in whole
 * without the express and written permission of Mt Pelerin Group SA.
 * Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * All matters regarding the intellectual property of this code or software
 * are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * E01: Vote must not be locked
 * E02: Vote must be locked
 * E03: Vote revealed must matched the vote locked
 */
contract SecretVoting is Voting {

  mapping(uint256 => mapping(address => bytes32)) hashes;

  /**
   * @dev lock the participant vote hash for a proposal
   */
  function lockHash(uint256 _proposalId, bytes32 _hash) public {
    require(!proposals[_proposalId].votes[msg.sender].locked, "E01");
    hashes[_proposalId][msg.sender] = _hash;
    proposals[_proposalId].votes[msg.sender].locked = true;
  }

  /**
   * @dev reveal the vote
   */
  function revealHash(
    uint256 _proposalId,
    uint8 _option,
    uint256 _salt) public
  {
    require(proposals[_proposalId].votes[msg.sender].locked, "E02");
    require(
      keccak256(
        abi.encodePacked(
          _proposalId,
          _option,
          msg.sender,
          _salt
        )
      ) == hashes[_proposalId][msg.sender],
      "E03"
    );
    vote(_proposalId, _option);
  }
}
