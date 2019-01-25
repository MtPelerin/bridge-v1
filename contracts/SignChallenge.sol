pragma solidity ^0.4.24;

import "./zeppelin/ownership/Ownable.sol";


/**
 * @title SignChallenge
 * @dev SignChallenge accept anyone to send a transaction with a challenge in it.
 * Any Oracle which create a challenge, may assess that someone do really own an address.
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
 * SC02: Challenge must be no more than 4 bytes
 * SC03: Target must not be null
 * SC04: Execution call must be successful
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 */
contract SignChallenge is Ownable {

  function () external payable {
    require(msg.value == 0, "SC01");
    require(msg.data.length == 4, "SC02");
    emit Challenge(msg.sender, msg.data);
  }

  function execute(address _target, bytes _data)
    public payable onlyOwner
  {
    require(_target != address(0), "SC03");
    // solium-disable-next-line security/no-call-value
    require(_target.call.value(msg.value)(_data), "SC04");
  }

  event Challenge(address indexed signer, bytes code);
}
