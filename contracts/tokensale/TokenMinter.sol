pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../token/MintableBridgeToken.sol";
import "../interface/IMPLTokensale.sol";
import "../interface/ISaleConfig.sol";


/**
 * @title TokenMinter
 * @dev TokenMinter contract
 * The contract explicit the whole issuance process of the Mt Pelerin's token
 *
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
 * E01: Token is not mintable anymore
 * E02: Minter cannot mint token anymore
 * E03: Minter can still mint token
 * E04: Token has already been minted
 * E05: Minter is not owner of the token
 * E06: Token minting failed
 * E07: Amount to mint must be greater than 0
 * E08: Cannot mint above configured total supply
 * E09: Total Supply is different from configured total supply
 * E10: Unable to finish the token minting
 * E11: Token can still be minted
 * E12: Ownership has not been transfered
*/
contract TokenMinter is IMintable, Ownable {
  using SafeMath for uint256;

  address public finalOwner;
  address public vaultLot1;

  bool public mintingFinished;

  ISaleConfig public config;
  MintableBridgeToken public token;

  modifier whenTokenMintable() {
    require(!token.mintingFinished(), "E01");
    _;
  }

  modifier beforeMintingFinished() {
    require(!mintingFinished, "E02");
    _;
  }

  modifier whenMintingFinished() {
    require(mintingFinished, "E03");
    _;
  }

  /**
   * @dev constructor
  */
  constructor(ISaleConfig _config, address _finalOwner) public
  {
    config = _config;
    finalOwner = _finalOwner;
  }

  /**
   * @dev implement IMintable interface
   */
  function mintingFinished() public view returns (bool) {
    return mintingFinished;
  }

  /**
   * @dev setup the token to be used by the minter
   * This step can be done righ after the contract is created.
   * It is splitted into to avoid having a more atomic construction
   * process and limit the gas of each transaction.
   */
  function setupToken(
    MintableBridgeToken _token,
    address _vaultLot1,
    address _vaultLot2,
    address _vaultReserved) public onlyOwner
  {
    // Ensure that the token has not been premint
    require(_token.totalSupply() == 0, "E04");
    require(!_token.mintingFinished(), "E01");
    
    // Ensure it has full ownership over the token to ensure
    // that only this contract will be allowed to mint
    require(_token.owner() == address(this), "E05");
    
    token = _token;
    vaultLot1 = _vaultLot1;

    // to be used at a later stages
    // in accordance with the purchase agreement
    require(
      token.mint(_vaultLot2, config.tokensaleLot2Supply()) &&
        token.mint(_vaultReserved, config.reservedSupply()),
      "E06"
    );
  }

  /**
   * @dev allows the owner to mint the token
   */
  function mint(address _to, uint256 _amount) public 
    onlyOwner whenTokenMintable beforeMintingFinished 
    returns (bool)
  {
    require(_amount > 0, "E07");
    uint256 unminted = config.tokenSupply().sub(token.totalSupply());
    require(unminted >= _amount, "E08");
    return token.mint(_to, _amount);
  }

  /**
   * @dev update this contract minting to finish
   */
  function finishMinting() public
    onlyOwner beforeMintingFinished returns (bool)
  {
    mintingFinished = true;
    return true;
  }

  /**
   * @dev mint remaining non distributed tokens
   * If some token remain unmint (unsold or roundering approximations)
   * they will be minted before the mint can be finished
   */
  function releaseToken() public
    onlyOwner whenMintingFinished whenTokenMintable
  {
    // 1- If needed, mint the remaing supply
    uint256 unminted = config.tokenSupply().sub(token.totalSupply());
    if (unminted > 0) {
      require(token.mint(vaultLot1, unminted), "E06");
    }
    require(token.totalSupply() == config.tokenSupply(), "E09");

    // 2- Prevent any further minting
    if (!token.mintingFinished()) {
      require(token.finishMinting(), "E10");
    }

    // 3- Transfer the ownership of the token to its final owner
    require(token.mintingFinished(), "E11");
    token.transferOwnership(finalOwner);
    require(token.owner() == finalOwner, "E12");
  }
}
