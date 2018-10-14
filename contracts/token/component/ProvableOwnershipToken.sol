pragma solidity ^0.4.24;

import "../../zeppelin/token/ERC20/StandardToken.sol";
import "../../zeppelin/ownership/Ownable.sol";
import "../../interface/IProvableOwnership.sol";
import "./AuditableToken.sol";


/**
 * @title ProvableOwnershipToken
 * @dev ProvableOwnershipToken is a StandardToken
 * with ability to record a proof of ownership
 *
 * When desired a proof of ownership can be generated.
 * The proof is stored within the contract.
 * A proofId is then returned.
 * The proof can later be used to retrieve the amount needed.
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 **/
contract ProvableOwnershipToken is IProvableOwnership, AuditableToken, Ownable {
  struct Proof {
    uint256 amount;
    uint256 dateFrom;
    uint256 dateTo;
  }
  mapping(address => mapping(uint256 => Proof)) internal proofs;
  mapping(address => uint256) internal proofLengths;

  /**
   * @dev number of proof stored in the contract
   */
  function proofLength(address _holder) public view returns (uint256) {
    return proofLengths[_holder];
  }

  /**
   * @dev amount contains for the proofId reccord
   */
  function proofAmount(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].amount;
  }

  /**
   * @dev date from which the proof is valid
   */
  function proofDateFrom(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].dateFrom;
  }

  /**
   * @dev date until the proof is valid
   */
  function proofDateTo(address _holder, uint256 _proofId)
    public view returns (uint256)
  {
    return proofs[_holder][_proofId].dateTo;
  }

  /**
   * @dev called to challenge a proof at a point in the past
   * Return the amount tokens owned by the proof owner at that time
   */
  function checkProof(address _holder, uint256 _proofId, uint256 _at)
    public view returns (uint256)
  {
    if (_proofId < proofLengths[_holder]) {
      Proof storage proof = proofs[_holder][_proofId];

      if (proof.dateFrom <= _at && _at <= proof.dateTo) {
        return proof.amount;
      }
    }
    return 0;
  }

  /**
   * @dev called to create a proof of token ownership
   */
  function createProof(address _holder) public {
    createProofInternal(_holder, balanceOf(_holder));
  }

  /**
   * @dev tranfer function with also create a proof of ownership to any of the participants
   * @param _proofSender if true a proof will be created for the sender
   * @param _proofReceiver if true a proof will be created for the receiver
   */
  function transferWithProofs(
    address _to,
    uint256 _value,
    bool _proofSender,
    bool _proofReceiver
  ) public returns (bool)
  {
    uint256 balanceBeforeFrom = balanceOf(msg.sender);
    uint256 balanceBeforeTo = balanceOf(_to);

    if (!super.transfer(_to, _value)) {
      return false;
    }

    transferPostProcessing(msg.sender, balanceBeforeFrom, _proofSender);
    transferPostProcessing(_to, balanceBeforeTo, _proofReceiver);
    return true;
  }

  /**
   * @dev tranfer function with also create a proof of ownership to any of the participants
   * @param _proofSender if true a proof will be created for the sender
   * @param _proofReceiver if true a proof will be created for the receiver
   */
  function transferFromWithProofs(
    address _from,
    address _to, 
    uint256 _value,
    bool _proofSender, bool _proofReceiver)
    public returns (bool)
  {
    uint256 balanceBeforeFrom = balanceOf(_from);
    uint256 balanceBeforeTo = balanceOf(_to);

    if (!super.transferFrom(_from, _to, _value)) {
      return false;
    }

    transferPostProcessing(_from, balanceBeforeFrom, _proofSender);
    transferPostProcessing(_to, balanceBeforeTo, _proofReceiver);
    return true;
  }

  /**
   * @dev can be used to force create a proof (with a fake amount potentially !)
   * Only usable by child contract internaly
   */
  function createProofInternal(address _holder, uint256 _amount) internal {
    uint proofId = proofLengths[_holder];
    // solium-disable-next-line security/no-block-members
    proofs[_holder][proofId] = Proof(_amount, lastTransactionAt(_holder), now);
    proofLengths[_holder] = proofId+1;
    emit ProofOfOwnership(_holder, proofId);
  }

  /**
   * @dev private function updating contract state after a transfer operation
   */
  function transferPostProcessing(
    address _holder,
    uint256 _balanceBefore,
    bool _proof) private
  {
    if (_proof) {
      createProofInternal(_holder, _balanceBefore);
    }
  }

  event ProofOfOwnership(address indexed holder, uint256 proofId);
}
