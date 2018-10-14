pragma solidity ^0.4.24;

import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "../interface/IMintableByLot.sol";
import "../token/MintableBridgeToken.sol";
import "../interface/ISaleConfig.sol";


/**
 * @title TokenMinter
 * @dev TokenMinter contract
 * The contract explicit the minting process of the Bridge Token
 *
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
 * E01: Configuration must be defined
 * E02: Final token owner must be defined
 * E03: There should be at least one lot
 * E04: Must have one vault per lot
 * E05: Each vault must be defined
 * E06: Token must be defined
 * E07: Token has already been defined
 * E08: Minter must be the token owner
 * E09: There should be no token supply
 * E10: Token minting must not be finished
 * E11: Minters must match tokensale configuration
 * E12: Tokensale configuration must matched lot definition
 * E13: Minter is not already configured for the lot
 * E14: Token must be defined
 * E15: Amount to mint must be greater than 0
 * E16: Mintable supply must be greater than amount to mint
 * E17: Can only finish minting for active minters
 * E18: No active minters expected for the lot
 * E19: There should be some remaining supply in the lot
 * E20: Minting must be successfull
 * E21: Token minting must not be finished
 * E22: There should be some unfinished lot(s)
 * E23: All minting must be processed
 * E24: Token minting must not be finished
 * E25: Finish minting must be successfull
 * E26: Token minting must be finished
*/
contract TokenMinter is IMintableByLot, Ownable {
  using SafeMath for uint256;

  struct MintableLot {
    uint256 mintableSupply;
    address vault;
    mapping(address => bool) minters;
    uint8 activeMinters;
  }

  MintableLot[] private mintableLots;
  mapping(address => uint256) public minterLotIds;

  uint256 public totalMintableSupply;
  address public finalTokenOwner;

  uint8 public activeLots;

  ISaleConfig public config;
  MintableBridgeToken public token;

  /**
   * @dev constructor
   */
  constructor(
    ISaleConfig _config,
    address _finalTokenOwner,
    address[] _vaults) public
  {
    require(address(_config) != 0, "E01");
    require(_finalTokenOwner != 0, "E02");

    uint256[] memory lots = _config.tokensaleLotSupplies();
    require(lots.length > 0, "E03");
    require(_vaults.length == lots.length, "E04");

    config = _config;
    finalTokenOwner = _finalTokenOwner;

    for (uint256 i = 0; i < lots.length; i++) {
      require(_vaults[i] != 0, "E05");
      uint256 mintableSupply = lots[i];
      mintableLots.push(MintableLot(mintableSupply, _vaults[i], 0));
      totalMintableSupply = totalMintableSupply.add(mintableSupply);
      activeLots++;
      emit LotCreated(i+1, mintableSupply);
    }
  }

  /**
   * @dev minter lotId
   */
  function minterLotId(address _minter) public view returns (uint256) {
    return minterLotIds[_minter];
  }

  /**
   * @dev lot mintable supply
   */
  function lotMintableSupply(uint256 _lotId) public view returns (uint256) {
    return mintableLots[_lotId].mintableSupply;
  }

  /**
   * @dev lot vault
   */
  function lotVault(uint256 _lotId) public view returns (address) {
    return mintableLots[_lotId].vault;
  }

  /**
   * @dev is lot minter
   */
  function isLotMinter(uint256 _lotId, address _minter)
    public view returns (bool)
  {
    return mintableLots[_lotId].minters[_minter];
  }

  /**
   * @dev lot active minters
   */
  function lotActiveMinters(uint256 _lotId) public view returns (uint256) {
    return mintableLots[_lotId].activeMinters;
  }

  /**
   * @dev implement IMintable interface
   */
  function mintingFinished() public view returns (bool) {
    return token.mintingFinished();
  }

  /**
   * @dev setup token and minters
   **/
  function setup(MintableBridgeToken _token, address[] _minters)
    public onlyOwner
  {
    require(address(_token) != 0, "E06");
    require(address(token) == 0, "E07");
    // Ensure it has full ownership over the token to ensure
    // that only this contract will be allowed to mint
    require(_token.owner() == address(this), "E08");
    token = _token;
    
    // Ensure that the token has not been premint
    require(token.totalSupply() == 0, "E09");
    require(!token.mintingFinished(), "E10");
    
    require(_minters.length == config.tokensalesCount(), "E11");
    for (uint256 i = 0; i < _minters.length; i++) {
      if (_minters[i] != address(0)) {
        setupMinter(_minters[i], i);
      }
    }
  }

  /**
   * @dev setup minter
   */
  function setupMinter(address _minter, uint256 _tokensaleId)
    public onlyOwner
  {
    uint256 lotId = config.lotId(_tokensaleId);
    require(lotId < mintableLots.length, "E12");
    MintableLot storage lot = mintableLots[lotId];
    require(!lot.minters[_minter], "E13");
    lot.minters[_minter] = true;
    lot.activeMinters++;
    minterLotIds[_minter] = lotId;
    emit MinterAdded(lotId, _minter);
  }

  /**
   * @dev mint the token from the corresponding lot
   */
  function mint(address _to, uint256 _amount)
    public returns (bool)
  {
    require(address(token) != 0, "E14");
    require(_amount > 0, "E15");
    
    uint256 lotId = minterLotIds[msg.sender];
    MintableLot storage lot = mintableLots[lotId];

    require(lot.mintableSupply >= _amount, "E16");

    lot.mintableSupply = lot.mintableSupply.sub(_amount);
    totalMintableSupply = totalMintableSupply.sub(_amount);
    return token.mint(_to, _amount);
  }

  /**
   * @dev update this contract minting to finish
   */
  function finishMinting() public returns (bool) {
    return finishMintingInternal(msg.sender);
  }

  /**
   * @dev update this contract minting to finish
   */
  function finishMintingRestricted(address _minter)
    public onlyOwner returns (bool)
  {
    return finishMintingInternal(_minter);
  }

  /**
   * @dev update this contract minting to finish
   */
  function finishMintingInternal(address _minter)
    public returns (bool)
  {
    uint256 lotId = minterLotIds[_minter];
    MintableLot storage lot = mintableLots[lotId];
    require(lot.minters[_minter], "E17");

    lot.minters[_minter] = false;
    lot.activeMinters--;

    if (lot.activeMinters == 0 && lot.mintableSupply == 0) {
      finishLotMintingPrivate(lotId);
    }
    return true;
  }

  /**
   * @dev mint remaining non distributed tokens for a lot
   */
  function mintRemainingLot(uint256 _lotId)
    public returns (bool)
  {
    MintableLot storage lot = mintableLots[_lotId];
    require(lot.activeMinters == 0, "E18");
    require(lot.mintableSupply > 0, "E19");

    require(token.mint(lot.vault, lot.mintableSupply), "E20");
    totalMintableSupply = totalMintableSupply.sub(lot.mintableSupply);
    lot.mintableSupply = 0;
 
    finishLotMintingPrivate(_lotId);
    return true;
  }

  /**
   * @dev mint remaining non distributed tokens
   * If some token remain unmint (unsold or roundering approximations)
   * they will be minted before the mint can be finished
   **/
  function mintAllRemaining() public onlyOwner returns (bool) {
    require(!token.mintingFinished(), "E21");
    require(activeLots > 0, "E22");
   
    if (totalMintableSupply > 0) {
      for (uint256 i = 0; i < mintableLots.length; i++) {
        MintableLot storage lot = mintableLots[i];
        if (lot.mintableSupply > 0) {
          mintRemainingLot(i);
        }
      }
    }
    return true;
  }

  /**
   * @dev finish token minting
   */
  function finishTokenMinting() public onlyOwner returns (bool) {
    require(totalMintableSupply == 0, "E23");
    require(!token.mintingFinished(), "E24");
    require(token.finishMinting(), "E25");
    
    require(token.mintingFinished(), "E26");
    token.transferOwnership(finalTokenOwner);
    emit TokenReleased();
  }

  /**
   * @dev finish lot minting
   */
  function finishLotMintingPrivate(uint256 _lotId) private {
    activeLots--;
    emit LotMinted(_lotId);
  }

  event LotCreated(uint256 lotId, uint256 tokenSupply);
  event MinterAdded(uint256 lotId, address minter);
  event LotMinted(uint256 lotId);
  event TokenReleased();
}
