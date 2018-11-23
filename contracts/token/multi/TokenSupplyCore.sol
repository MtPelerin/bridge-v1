pragma solidity ^0.4.24;


import "../../zeppelin/math/SafeMath.sol";
import "./TokenCore.sol";


/**
 * @title TokenSupplyCore
 * @dev TokenSupplyCore contract
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subjects to Swiss Law without reference to its conflicts of law rules.
 */
contract TokenSupplyCore is TokenCore {
  using SafeMath for uint256;

  enum SupplyMode {
    ISSUABLE, MINTABLE
  }

  struct TokenSupply {
    SupplyMode supplyMode;
    bool mintingFinished;

    // Overflow on attributes below is an expected behavior
    // The contract should not be locked because
    // the max uint256 value is reached
    // Usage of these values must handle the overflow
    uint256 allTimeIssued; // potential overflow
    uint256 allTimeRedeemed; // potential overflow
  }

  mapping(address => TokenSupply) tokenSupplies;

  /**
   * @dev supply Mode
   */
  function supplyMode() public view returns (SupplyMode) {
    return tokenSupplies[msg.sender].supplyMode;
  }

  /**
   * @dev minting finished
   */
  function mintingFinished() public view returns (bool) {
    return tokenSupplies[msg.sender].mintingFinished;
  }

  /**
   * @dev allTimeIssued
   */
  function allTimeIssued() public view returns (uint256) {
    return tokenSupplies[msg.sender].allTimeIssued;
  }

  /**
   * @dev allTimeRedeemed
   */
  function allTimeRedeemed() public view returns (uint256) {
    return tokenSupplies[msg.sender].allTimeRedeemed;
  }

  /**
   * @dev if token mintable
   */
  function ifMintable(TokenSupply _tokenSupply) private pure {
    require(_tokenSupply.supplyMode == SupplyMode.MINTABLE, "MT02");
    require(!_tokenSupply.mintingFinished, "MT02");
  }

  /**
   * @dev if token issuable
   */
  function ifIssuable(TokenSupply _tokenSupply) private pure {
    require(_tokenSupply.supplyMode == SupplyMode.ISSUABLE, "MT03");
  }

  /**
   * @dev setup token
   */
  function setupTokenSupply(address _token, uint256 _supplyMode) public {
    tokenSupplies[_token].supplyMode = SupplyMode(_supplyMode);
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  ) public returns (bool)
  {
    ifMintable(tokenSupplies[msg.sender]);

    Token storage token = tokens[msg.sender];
    token.totalSupply_ = token.totalSupply_.add(_amount);
    token.balances[_to] = token.balances[_to].add(_amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public returns (bool) {
    TokenSupply storage tokenSupply = tokenSupplies[msg.sender];
    ifMintable(tokenSupply);
    tokenSupply.mintingFinished = true;
    return true;
  }

  /**
   * @dev called by the owner to increase the supply
   */
  function issue(address _to, uint256 _amount) public returns (bool) {
    TokenSupply storage tokenSupply = tokenSupplies[msg.sender];
    ifIssuable(tokenSupply);

    Token storage token = tokens[msg.sender];
    token.balances[_to] = token.balances[_to].add(_amount);
    token.totalSupply_ = token.totalSupply_.add(_amount);

    tokenSupply.allTimeIssued += _amount;
    return true;
  }

  /**
   * @dev called by the owner to decrease the supply
   */
  function redeem(address _to, uint256 _amount) public returns (bool) {
    TokenSupply storage tokenSupply = tokenSupplies[msg.sender];
    ifIssuable(tokenSupply);

    Token storage token = tokens[msg.sender];
    token.balances[_to] = token.balances[_to].sub(_amount);
    token.totalSupply_ = token.totalSupply_.sub(_amount);

    tokenSupply.allTimeRedeemed += _amount;
    return true;
  }
}
