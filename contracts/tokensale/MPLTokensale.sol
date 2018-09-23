pragma solidity ^0.4.24;

import "../interface/ISaleConfig.sol";
import "../interface/IMPLTokensale.sol";
import "../interface/IMintable.sol";
import "../interface/IUserRegistry.sol";
import "./TokenMinter.sol";
import "./MPLTokensalePlan.sol";


/**
 * @title MPLTokensale
 * @dev MPLTokensale contract
 * This contract manage a sale as follow:
 *  - sale happens between a open and close date
 *  - ETHCHF in the form of WEI/Cent) rate is provided
 *    once the sale is over
 *  - investors must be first registred in order to invest
 *  - investors must claim their tokens at the end of the sale
 *    before the distribution is over.
 *  - The minter is given back to contract owner after the sale
 *    It is the minter contract responsability to handle
 *    the non distributed tokens
 *
 * Below a more technical view of the different events:
 *  - The contract is created with a sale configuration and a user
 *    registry
 *  - The minter contract is then set with the ownership
 *    given to the private sale
 *  - The sales happens and the contract receive ETH from investors
 *    During the sales, CHF investment may be added as they are received
 *  - At the end of the sales non-ETH, non-CHF investments are
 *    all converted into CHF and are then added by the admin.
 *    This includes Bitcoin, USD, EUR, ...
 *    Please contact the sale operator for more details on execution rates
 *  - Investments are reviewed for compliance by the admin
 *    and rejected if required
 *  - The ETHCHF rate is defined and if the conversion shows that 
 *    too much CHF were raised then a refund ratio is defined to
 *    compensate ETH investors
 *  - During the preparation of mint, the extra ETH received is refunfed
 *    and the number of tokens is defined
 *  - The minting can finally occures
 *  - After the distribution period, the minter is given back to the
 *    contract owner.
 *  - Minter contract should be look to see how more token
 *    may be minted.
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
 * E01: No data are expected for the default function
 * E02: Minter must not be defined already
 * E03: Ownership of minter must be given to this contract
 * E04: Minter must be able to mint
 * E05: Not enough ETH to reject
 * E06: Not enough CHF to rejct
 * E07: ETHCHF rate must be greater than 0
 * E08: ETHCHF rate must be defined
 * E09: Investor must exist
 * E10: Investor has already been prepared
 * E11: Not all investors has been prepared
 * E12: Tokens have already been minted
 * E13: Not all investors have received their tokens
 * E14: Minter continue to allow token minting
 * E15: Minter ownership has not been given back to owner
 * E16: User must be valid
 * E17: Enough CHF is already raised
 * E18: Investment in ETH must be above the minimal investment
 * E19: Investor has no tokens
 */
contract MPLTokensale is IMPLTokensale, MPLTokensalePlan {

  address public vault;
  TokenMinter public minter;
  IUserRegistry public userRegistry;

  struct Investor {
    // ETH invested. The unit used is the Wei
    uint256 depositETH;

    // CHF invested (this includes as well depositETH
    // once converted into CHF). The unit used is the cents
    uint256 depositCHF;

    // Tokens to be minted for the investors
    uint256 tokens;

    // Address to which ERC20 will be minted.
    // ETH in excess will also be refunded to this address.
    address destination;

    // Investor is prepared for minting
    bool prepared;
    // Investor has been refunded
    bool refunded;
    // Investor's tokens has been minted
    bool minted;
  }
  mapping(uint256 => Investor) investors; // userId => Investor

  uint256 public investorCount;
  uint256 public contributorCount;
  uint256 public preparedCount;
  uint256 public mintedCount;

  // WEICHF rate is in ETH_wei/CHF_cents with no fractional parts
  uint256 public rateWEIPerCHFCent;
  uint256 public raisedCHF; // The unit is the cent
  uint256 public raisedETH;

  // total with raisedCHF and raisedETH converted in CHF
  uint256 public totalRaisedCHF;
  uint256 public refundETH;

  uint256 public refundRatio;
  uint256 constant public REFUND_ETH_PRECISION = 10 ** 9;
  uint256 constant public REFUND_CHF_UNSPENT_MIN = 10; // The unit is the cent
 
  /**
   * @dev Configure the MPL tokensale
   */
  constructor(
    address _vault,
    ISaleConfig _saleConfig,
    IUserRegistry _userRegistry
    ) MPLTokensalePlan(_saleConfig) public
  {
    vault = _vault;
    userRegistry = _userRegistry;
  }

  /**
   * @dev fallback function
   */
  function () external payable {
    require(msg.data.length == 0, "E01");
    investETH();
  }

  /**
   * @dev convert rate from ETH/CHF to WEI/CHFCents
   */
  function convertFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal) public pure returns (uint256)
  {
    if (_rateETHCHF == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateETHCHF);
  }

  /**
   * @dev convert rate to ETH/CHF from WEI/CHFCents
   */
  function convertToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal) public pure returns (uint256)
  {
    if (_rateWEIPerCHFCent == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateWEIPerCHFCent);
  }

  /**
   * @dev setup the token minter
   the MPL tokensale
   */
  function setupMinter(TokenMinter _minter)
    public whenStepIs(Stepname.CREATED)
  {
    require(address(minter) == address(0), "E02");
    require(_minter.owner() == address(this), "E03");
    require(!_minter.mintingFinished(), "E04");
    minter = _minter;
    nextStep();
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function vault() public view returns (address) {
    return vault;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function minter() public view returns (IMintable) {
    return minter;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  /**
   * @dev investor's depositETH
   */
  function investorDepositETH(uint256 _userId)
    public view returns (uint256)
  {
    return investors[_userId].depositETH;
  }

  /**
   * @dev investor's depositCHF
   */
  function investorDepositCHF(uint256 _userId)
    public view returns (uint256)
  {
    return investors[_userId].depositCHF;
  }

  /**
   * @dev investor's destination
   */
  function investorDestination(uint256 _userId)
    public view returns (address)
  {
    return investors[_userId].destination;
  }

  /**
   * @dev investor's tokens
   */
  function investorTokens(uint256 _userId)
    public view returns (uint256)
  {
    return investors[_userId].tokens;
  }

  /**
   * @dev investor is refunded
   */
  function investorIsRefunded(uint256 _userId)
    public view returns (bool)
  {
    return investors[_userId].refunded;
  }

  /**
   * @dev investor's tokens have been prepared
   */
  function investorIsPrepared(uint256 _userId)
    public view returns (bool)
  {
    return investors[_userId].prepared;
  }

  /**
   * @dev investor's tokens have been minted
   */
  function investorIsMinted(uint256 _userId)
    public view returns (bool)
  {
    return investors[_userId].minted;
  }

  /**
   * @dev count of investors
   */
  function investorCount() public view returns (uint256) {
    return investorCount;
  }

  /**
   * @dev count of contributors
   */
  function contributorCount() public view returns (uint256) {
    return contributorCount;
  }

  /**
   * @dev count of prepared investors
   */
  function preparedCount() public view returns (uint256) {
    return preparedCount;
  }

  /**
   * @dev count of minted investors
   */
  function mintedCount() public view returns (uint256) {
    return mintedCount;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function rateWEIPerCHFCent() public view returns (uint256) {
    return rateWEIPerCHFCent;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256)
  {
    return convertToETHCHF(rateWEIPerCHFCent, _rateETHCHFDecimal);
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function raisedCHF() public view returns (uint256) {
    return raisedCHF;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function totalRaisedCHF() public view returns (uint256) {
    return totalRaisedCHF;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function raisedETH() public view returns (uint256) {
    return raisedETH;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function refundETH() public view returns (uint256) {
    return refundETH;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function refundRatio() public view returns (uint256) {
    return refundRatio;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function refundETHPrecision() public pure returns (uint256) {
    return REFUND_ETH_PRECISION;
  }

  /**
   * @dev getter need to be declared to comply with IMPLTokensale interface
   */
  function refundCHFUnspentMin() public pure returns (uint256) {
    return REFUND_CHF_UNSPENT_MIN;
  }

  /**
   * @dev Invest ETH callable by any registred participants
   */
  function investETH() public payable whenStepIs(Stepname.LIVE) {
    invest(msg.sender, msg.value, 0);
  }

  /**
   * @dev Add off chain investments with their CHF counter value
   * The operation is done by the contract owner
   * It may be done outside the sale timeframes
   * as depending on the investments
   * origin extra compliance checks may be needed.
   */
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public onlyOwner whenBetweenSteps(Stepname.READY, Stepname.REVIEW)
  {
    invest(_investor, 0, _amountCHF);
  }

 /**
   * @dev reject ETH funds in case of unability to meet compliance
   * requirements or simply if an investor sent too much ETH
   */
  function rejectETHFunds(uint256 _userId, uint256 _amount)
    public onlyOwner whenBetweenSteps(Stepname.READY, Stepname.REVIEW)
  {
    Investor storage investor = investors[_userId];
    require(investor.depositETH >= _amount, "E05");
    investor.depositETH = investor.depositETH.sub(_amount);
    investor.destination.transfer(_amount);
    emit InvestmentETHRejected(investor.destination, _amount);
  }

  /**
   * @dev reject CHF funds in case of unability to meet
   * financial compliance requirements
   */
  function rejectCHFFunds(uint256 _userId, uint256 _amount)
    public onlyOwner whenBetweenSteps(Stepname.READY, Stepname.REVIEW)
  {
    Investor storage investor = investors[_userId];
    require(investor.depositCHF >= _amount, "E06");
    investor.depositCHF = investor.depositCHF.sub(_amount);
    raisedCHF = raisedCHF.sub(_amount);
    emit InvestmentCHFRejected(investor.destination, _amount);
  }

  /**
   * @dev Convert raised ETH to CHF and define the refund ratio
   * The function should be callable many times in order to correct
   * input errors on the ETHCHF rate
   *
   * @param _rateETHCHF rate (price of 1 ETH in CHF)
   * @param _rateETHCHFDecimal is the number of decimals in the first parameter 
   * Ex: 512.34 is provided as (51234, 2)
   */
  function defineRate(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public onlyOwner whenStepIs(Stepname.REVIEW) 
  {
    require(_rateETHCHF != 0, "E07");
    // The rate is inverted to maximize the decimals stored
    rateWEIPerCHFCent = convertFromETHCHF(_rateETHCHF, _rateETHCHFDecimal);

    evaluateSale();
  }

  /**
   * @dev processSale
   * Investments have been reviewed. The ETHCHF rate is fixed
   */
  function processSale()
    public onlyOwner whenStepIs(Stepname.REVIEW)
  {
    require(rateWEIPerCHFCent != 0, "E08");
    evaluateSale();

    nextStep();
    emit SaleProcessed(totalRaisedCHF, refundETH);
  }

 /**
   * @dev Prepare minting the tokens for an investor
   * This operation will define the number of tokens mintable
   * for that investor
   * This operation also triggers the ETH refund
   */
  function prepareMinting(uint256 _userId)
    public onlyOwner whenStepIs(Stepname.PREPARE)
  {
    Investor storage investor = investors[_userId];
    require(investor.destination != address(0), "E09");
    require(!investor.prepared, "E10");

    uint256 refundETHAmount = 0;
    uint256 contributionCHF = investor.depositCHF;

    if (investor.depositETH > 0) {
      if (refundRatio > 0) {
        refundETHAmount = investor.depositETH.mul(
          REFUND_ETH_PRECISION).div(refundRatio);
      }

      uint256 convertedCHFDeposit = (
        investor.depositETH.sub(refundETHAmount)).div(rateWEIPerCHFCent);
      contributionCHF = contributionCHF.add(convertedCHFDeposit);
    }

    if (contributionCHF > 0) {
      investor.tokens = contributionCHF.div(saleConfig.tokenPriceCHF());
      uint256 unspentCHFAmount = contributionCHF.sub(
        investor.tokens.mul(saleConfig.tokenPriceCHF()));
      contributorCount++;

      if (unspentCHFAmount > REFUND_CHF_UNSPENT_MIN) {
        refundETHAmount = refundETHAmount.add(
          unspentCHFAmount.mul(rateWEIPerCHFCent));
      }
   }

    if (!investor.refunded && refundETHAmount > 0) {
      investor.refunded = true;
      investor.destination.transfer(refundETHAmount);
    }

    investor.prepared = true;
    preparedCount++;
  }

  /**
   * @dev prepare minting tokens for many users
   */
  function prepareMintingForManyUsers(uint256[] _userIds)
    public onlyOwner whenStepIs(Stepname.PREPARE)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      prepareMinting(_userIds[i]);
    }
  }

  /**
   * @dev enable minting
   **/
  function enableMinting() public onlyOwner whenStepIs(Stepname.PREPARE) {
    require(preparedCount == investorCount, "E10");
    nextStep();
  }

  /**
   * @dev mint tokens for a user
   */
  function mintSelf() public whenStepIs(Stepname.MINT) {
    uint256 userId = userRegistry.userId(msg.sender);
    mint(userId);
  }

  /**
   * @dev mint tokens for a user
   */
  function mint(uint256 _userId) public whenStepIs(Stepname.MINT) {
    Investor storage investor = investors[_userId];
    require(investor.destination != address(0), "E09");
    require(investor.tokens > 0, "E19");
    require(!investor.minted, "E12");
    if (minter.mint(investor.destination, investor.tokens)) {
      investor.minted = true;
      mintedCount++;
    }
  }

  /**
   * @dev mint tokens for many users
   */
  function mintForManyUsers(uint256[] _userIds)
    public onlyOwner whenBetweenSteps(Stepname.MINT, Stepname.FINALIZE)
  {
    for (uint256 i = 0; i < _userIds.length; i++) {
      mint(_userIds[i]);
    }
  }

  /**
   * @dev withdraw ETH funds from the MPL tokensale
   */
  function withdrawETHFunds() public onlyOwner {
    uint256 balance = address(this).balance;
    vault.transfer(balance);
    emit WithdrawETH(balance);
  }

  /**
   * @dev finish the distribution and release the minter ownership
   */
  function finishDistribution() public
    whenStepIs(Stepname.FINALIZE) onlyOwner
  {
    require(mintedCount == contributorCount, "E13");

    if (!minter.mintingFinished()) {
      minter.finishMinting();
    }

    if (minter.owner() == address(this)) {
      minter.transferOwnership(owner);
    }

    require(minter.mintingFinished(), "E14");
    require(minter.owner() == owner, "E15");
    nextStep();
  }

  /**
   * @dev invest ETH callable by any registred participants
   */
  function invest(
    address _destination,
    uint256 _depositETH,
    uint256 _depositCHF) internal
  {
    uint256 userId = userRegistry.userId(_destination);
    require(userRegistry.isValid(userId), "E16");
    Investor storage investor = investors[userId];

    if (_depositCHF > 0) {
      require(
        saleConfig.tokensaleLot1HardCapCHF() >= raisedCHF.add(_depositCHF),
        "E17"
      );
    } else {
      require(
        investor.depositETH.add(
          _depositETH
        ) > saleConfig.minimalETHInvestment(),
        "E18"
      );
    }

    if (investor.destination == address(0)) {
      investors[userId] = Investor(
        _depositETH,
        _depositCHF,
        0,
        _destination,
        false,
        false,
        false
      );
      raisedCHF = raisedCHF.add(_depositCHF);
      investorCount++;
      emit Investment(_destination, _depositETH, _depositCHF);
    } else {
      if (_depositETH > 0) {
        investor.depositETH = investor.depositETH.add(_depositETH);
        emit Investment(investor.destination, _depositETH, 0);
      }

      if (_depositCHF > 0) {
        investor.depositCHF = investor.depositCHF.add(_depositCHF);
        raisedCHF = raisedCHF.add(_depositCHF);
        emit Investment(investor.destination, 0, _depositCHF); 
      }
    }
  }

  /**
   * @dev evaluate the value of the sale
   * The function should be callable many times in order to correct any input errors
   *
   */
  function evaluateSale() private {
    totalRaisedCHF = 0;
    raisedETH = address(this).balance;
    uint256 admissibleETH = (
      saleConfig.tokensaleLot1HardCapCHF().sub(raisedCHF)).mul(rateWEIPerCHFCent);
    refundETH = 0;
    if ( raisedETH > admissibleETH ) {
      // Due to variability in the ETHCHF rate too many ETH were raised
      // Excess ETHs are refunded equally amoung ETH investors
      refundETH = raisedETH.sub(admissibleETH); 
      refundRatio = raisedETH.mul(REFUND_ETH_PRECISION).div(refundETH);
      totalRaisedCHF = raisedCHF.add(admissibleETH.div(rateWEIPerCHFCent));
    } else {
      totalRaisedCHF = raisedCHF.add(raisedETH.div(rateWEIPerCHFCent));
    }
  }

  event Investment(
    address indexed investor,
    uint256 amountETH,
    uint256 amountCHF
  );
  event InvestmentETHRejected(address indexed investor, uint256 amount);
  event InvestmentCHFRejected(address indexed investor, uint256 amount);
  event SaleProcessed(uint256 raisedCHF, uint256 refundETH);
  event WithdrawETH(uint256 amount);
}
