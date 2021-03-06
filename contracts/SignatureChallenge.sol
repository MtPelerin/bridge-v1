pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";


/**
 * @title SignatureChallenge
 * @dev SignatureChallenge accept anyone to send a transaction with a challenge in it.
 * Any Oracle which creates a challenge, may use it to assess that someone does really 
 * own a given address.
 *
 * @notice Copyright © 2016 - 2019 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 *
 * Error messages
 * SC01: No ETH must be provided for the challenge
 * SC02: Target must not be null
 * SC03: Execution call must be successful
 * SC04: Challenges are not active
 * SC05: Challenge must not be longer than challengeBytes
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract SignatureChallenge is Ownable {

  bool public active = true;
  uint8 public challengeBytes = 2;

  function () external payable {
    require(msg.value == 0, "SC01");
    acceptCode(msg.data);
  }

  /**
   * @dev Update Challenge
   */
  function updateChallenge(
    bool _active,
    uint8 _challengeBytes,
    bytes _testCode) public onlyOwner
  {
    if (!signChallengeWhenValid()) {
      active = _active;
      challengeBytes = _challengeBytes;
      emit ChallengeUpdated(_active, _challengeBytes);

      if (active) {
        acceptCode(_testCode);
      }
    }
  }

  /**
   * @dev execute
   */
  function execute(address _target, bytes _data)
    public payable
  {
    if (!signChallengeWhenValid()) {
      executeOwnerRestricted(_target, _data);
    }
  }

  /**
   * @dev Makes sure to accept the code even it matches a valid function signature.
   */
  function signChallengeWhenValid() private returns (bool) {
    // Prevent any loophole against the default function
    // SignatureChallenge may be set inactive to bypass this feature
    if (active && msg.data.length == challengeBytes) {
      require(msg.value == 0, "SC01");
      acceptCode(msg.data);
      return true;
    }
    return false;
  }

  /**
   * @dev execute restricted to owner
   */
  function executeOwnerRestricted(address _target, bytes _data)
    private onlyOwner
  {
    require(_target != address(0), "SC02");
    // solium-disable-next-line security/no-call-value
    require(_target.call.value(msg.value)(_data), "SC03");
  }

  /**
   * @dev accept code
   */
  function acceptCode(bytes _code) private {
    require(active, "SC04");
    require(_code.length == challengeBytes, "SC05");
    emit ChallengeSigned(msg.sender, _code);
  }

  event ChallengeUpdated(bool active, uint8 length);
  event ChallengeSigned(address indexed signer, bytes code);
}
