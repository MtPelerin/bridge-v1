pragma solidity ^0.4.24;


import "../../zeppelin/math/SafeMath.sol";
import "./TokenCore.sol";


/**
 * @title SupplyGenerationCore
 * @dev SupplyGenerationCore contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract SupplyGenerationCore is TokenCore {
  using SafeMath for uint256;

  enum SupplyMode {
    ISSUABLE, MINTABLE
  }

  struct SupplyGeneration {
    SupplyMode supplyMode;
    bool mintingFinished;

    // Overflow on attributes below is an expected behavior
    // The contract should not be locked because
    // the max uint256 value is reached
    // Usage of these values must handle the overflow
    uint256 allTimeIssued; // potential overflow
    uint256 allTimeRedeemed; // potential overflow
  }

  mapping(bytes32 => SupplyGeneration) supplyGenerations;

  function mintingFinished(bytes32 _key) public view returns (bool) {
    return supplyGenerations[_key].mintingFinished;
  }

  function ifMintable(SupplyGeneration _supplyGeneration) private pure {
    require(_supplyGeneration.supplyMode == SupplyMode.MINTABLE, "MT02");
    require(!_supplyGeneration.mintingFinished, "MT02");
  }

  function ifIssuable(SupplyGeneration _supplyGeneration) private pure {
    require(_supplyGeneration.supplyMode == SupplyMode.ISSUABLE, "MT03");
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    bytes32 _key,
    address _to,
    uint256 _amount
  ) public returns (bool)
  {
    ifMintable(supplyGenerations[_key]);

    Token storage token = tokens[_key];
    token.totalSupply_ = token.totalSupply_.add(_amount);
    token.balances[_to] = token.balances[_to].add(_amount);
    //emit Mint(_to, _amount);
    //emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting(bytes32 _key) public returns (bool) {
    SupplyGeneration storage supplyGeneration = supplyGenerations[_key];
    ifMintable(supplyGeneration);
    supplyGeneration.mintingFinished = true;
    //emit MintFinished();
    return true;
  }

  /**
   * @dev called by the owner to increase the supply
   */
  function issue(bytes32 _key, address _to, uint256 _amount) public {
    SupplyGeneration storage supplyGeneration = supplyGenerations[_key];
    ifIssuable(supplyGeneration);

    Token storage token = tokens[_key];
    token.balances[_to] = token.balances[_to].add(_amount);
    token.totalSupply_ = token.totalSupply_.add(_amount);

    supplyGeneration.allTimeIssued += _amount;
    //emit Issued(_amount);
  }

  /**
   * @dev called by the owner to decrease the supply
   */
  function redeem(bytes32 _key, address _to, uint256 _amount) public {
    SupplyGeneration storage supplyGeneration = supplyGenerations[_key];
    ifIssuable(supplyGeneration);

    Token storage token = tokens[_key];
    token.balances[_to] = token.balances[_to].sub(_amount);
    token.totalSupply_ = token.totalSupply_.sub(_amount);

    supplyGeneration.allTimeRedeemed += _amount;
    //emit Redeemed(_amount);
  }
}
