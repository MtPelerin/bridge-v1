pragma solidity ^0.4.24;


/**
 * @title IRates
 * @dev IRates interface
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * @notice Copyright © 2016 - 2018 Mt Pelerin Group SA - All Rights Reserved
 * @notice This content cannot be used, copied or reproduced in part or in whole
 * @notice without the express and written permission of Mt Pelerin Group SA.
 * @notice Written by *Mt Pelerin Group SA*, <info@mtpelerin.com>
 * @notice All matters regarding the intellectual property of this code or software
 * @notice are subject to Swiss Law without reference to its conflicts of law rules.
 **/
contract IRates {
  function updateManyRates(
    uint256[] _tokenIds,
    uint256[] _rates,
    uint256[] _invertedRates) external;

  function referenceToken() public view returns (address);
  function ratePrecision() public view returns (uint256);
  function tokens() public view returns (address[]);
  
  function rate(address _token) public view returns (uint256);
  function invertedRate(address _token) public view returns (uint256);
  function updatedAt(address _token) public view returns (uint256);

  function updateRate(uint256 _tokenId, uint256 _rate, uint256 _invertedRate)
    public;

  function addToken(address _token, uint256 _rate, uint256 _invertedRate)
    public;

  function addManyTokens(
    address[] _tokens,
    uint256[] _rates,
    uint256[] _invertedRates) public;

  function removeToken(uint256 _tokenId) public;
  function removeManyTokens(uint256[] _tokenIds) public;
 
  function updateReferenceToken(address _referenceToken) public;
  function updateRatePrecision(uint256 _ratePrecision) public;
}
