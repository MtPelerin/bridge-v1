pragma solidity ^0.4.24;

import "./Voting.sol";


/**
 * @title SecretVoting
 * @dev SecretVoting contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
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
