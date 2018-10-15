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
 * TM01: Configuration must be defined
 * TM02: Final token owner must be defined
 * TM03: There should be at least one lot
 * TM04: Must have one vault per lot
 * TM05: Each vault must be defined
 * TM06: Token must be defined
 * TM07: Token has already been defined
 * TM08: Minter must be the token owner
 * TM09: There should be no token supply
 * TM10: Token minting must not be finished
 * TM11: Minters must match tokensale configuration
 * TM12: Tokensale configuration must matched lot definition
 * TM13: Minter is not already configured for the lot
 * TM14: Token must be defined
 * TM15: Amount to mint must be greater than 0
 * TM16: Mintable supply must be greater than amount to mint
 * TM17: Can only finish minting for active minters
 * TM18: No active minters expected for the lot
 * TM19: There should be some remaining supply in the lot
 * TM20: Minting must be successfull
 * TM21: Token minting must not be finished
 * TM22: There should be some unfinished lot(s)
 * TM23: All minting must be processed
 * TM24: Token minting must not be finished
 * TM25: Finish minting must be successfull
 * TM26: Token minting must be finished
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
    require(address(_config) != 0, "TM01");
    require(_finalTokenOwner != 0, "TM02");

    uint256[] memory lots = _config.tokensaleLotSupplies();
    require(lots.length > 0, "TM03");
    require(_vaults.length == lots.length, "TM04");

    config = _config;
    finalTokenOwner = _finalTokenOwner;

    for (uint256 i = 0; i < lots.length; i++) {
      require(_vaults[i] != 0, "TM05");
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
    require(address(_token) != 0, "TM06");
    require(address(token) == 0, "TM07");
    // Ensure it has full ownership over the token to ensure
    // that only this contract will be allowed to mint
    require(_token.owner() == address(this), "TM08");
    token = _token;
    
    // Ensure that the token has not been premint
    require(token.totalSupply() == 0, "TM09");
    require(!token.mintingFinished(), "TM10");
    
    require(_minters.length == config.tokensalesCount(), "TM11");
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
    require(lotId < mintableLots.length, "TM12");
    MintableLot storage lot = mintableLots[lotId];
    require(!lot.minters[_minter], "TM13");
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
    require(address(token) != 0, "TM14");
    require(_amount > 0, "TM15");
    
    uint256 lotId = minterLotIds[msg.sender];
    MintableLot storage lot = mintableLots[lotId];

    require(lot.mintableSupply >= _amount, "TM16");

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
    require(lot.minters[_minter], "TM17");

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
    require(lot.activeMinters == 0, "TM18");
    require(lot.mintableSupply > 0, "TM19");

    require(token.mint(lot.vault, lot.mintableSupply), "TM20");
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
    require(!token.mintingFinished(), "TM21");
    require(activeLots > 0, "TM22");
   
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
    require(totalMintableSupply == 0, "TM23");
    require(!token.mintingFinished(), "TM24");
    require(token.finishMinting(), "TM25");
    
    require(token.mintingFinished(), "TM26");
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
