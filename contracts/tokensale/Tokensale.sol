pragma solidity ^0.4.24;

import "../interface/IUserRegistry.sol";
import "../interface/ITokensale.sol";
import "../interface/IRatesProvider.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../Authority.sol";


/**
 * @title Tokensale
 * @dev Tokensale interface
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
 * TOS01: It must be before the sale is opened
 * TOS02: Sale must be open
 * TOS03: It must be before the sale is closed
 * TOS04: It must be after the sale is closed
 * TOS05: No data must be sent while sending ETH
 * TOS06: Share Purchase Agreement Hashes must match
 * TOS07: User/Investor must exist
 * TOS08: SPA must be accepted before any ETH investment
 * TOS09: Cannot update schedule once started
 * TOS10: Investor must exist
 * TOS11: Cannot allocate more tokens than available supply
 * TOS12: InvestorIds and amounts must match
 * TOS13: Investor must exist
 * TOS14: Must refund ETH unspent
 * TOS15: Must withdraw ETH to vaultETH
 * TOS16: Cannot invest onchain and offchain at the same time
 * TOS17: A ETHCHF rate must exist to invest
 * TOS18: User must be valid
 * TOS19: Cannot invest if no more tokens
 * TOS20: Cannot unspent more CHF than BASE_TOKEN_PRICE_CHF
 * TOS21: Token transfer must be successfull
 */
contract Tokensale is ITokensale, Authority {
  using SafeMath for uint256;

  uint256 public constant KYC_LEVEL_KEY = 1;

  /* General sale details */
  ERC20 public token;
  address public vaultETH;
  address public vaultERC20;
  IUserRegistry public userRegistry;
  IRatesProvider public ratesProvider;

  uint256 public minimalBalance = MINIMAL_BALANCE;
  bytes32 public sharePurchaseAgreementHash;

  uint256 public startAt = 4102441200;
  uint256 public endAt = 4102441200;
  uint256 public raisedETH;
  uint256 public raisedCHF;
  uint256 public totalRaisedCHF;
  uint256 public totalUnspentETH;
  uint256 public totalRefundedETH;
  uint256 public allocatedTokens;

  struct Investor {
    uint256 unspentETH;
    uint256 investedCHF;
    bool acceptedSPA;
    uint256 allocations;
    uint256 tokens;
  }
  mapping(uint256 => Investor) investors;
  mapping(uint256 => uint256) investorLimits;
  uint256 public investorCount;

  /**
   * @dev Throws if sale is not open
   */
  modifier beforeSaleIsOpened {
    require(currentTime() < startAt, "TOS01");
    _;
  }

  /**
   * @dev Throws if sale is not open
   */
  modifier saleIsOpened {
    require(currentTime() >= startAt && currentTime() <= endAt, "TOS02");
    _;
  }

  /**
   * @dev Throws once the sale is closed
   */
  modifier beforeSaleIsClosed {
    require(currentTime() <= endAt, "TOS03");
    _;
  }

  /**
   * @dev constructor
   */
  constructor(
    ERC20 _token,
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    address _vaultERC20,
    address _vaultETH
  ) public
  {
    token = _token;
    userRegistry = _userRegistry;
    ratesProvider = _ratesProvider;
    vaultERC20 = _vaultERC20;
    vaultETH = _vaultETH;
  }

  /**
   * @dev fallback function
   */
  function () external payable {
    require(msg.data.length == 0, "TOS05");
    investETH();
  }

  /**
   * @dev returns the token sold
   */
  function token() public view returns (ERC20) {
    return token;
  }

  /**
   * @dev returns the vault use to
   */
  function vaultETH() public view returns (address) {
    return vaultETH;
  }

  /**
   * @dev returns the vault to receive ETH
   */
  function vaultERC20() public view returns (address) {
    return vaultERC20;
  }

  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  function ratesProvider() public view returns (IRatesProvider) {
    return ratesProvider;
  }

  function sharePurchaseAgreementHash() public view returns (bytes32) {
    return sharePurchaseAgreementHash;
  }

  /* Sale status */
  function startAt() public view returns (uint256) {
    return startAt;
  }

  function endAt() public view returns (uint256) {
    return endAt;
  }

  function raisedETH() public view returns (uint256) {
    return raisedETH;
  }

  function raisedCHF() public view returns (uint256) {
    return raisedCHF;
  }

  function totalRaisedCHF() public view returns (uint256) {
    return totalRaisedCHF;
  }

  function totalUnspentETH() public view returns (uint256) {
    return totalUnspentETH;
  }

  function totalRefundedETH() public view returns (uint256) {
    return totalRefundedETH;
  }

  function availableSupply() public view returns (uint256) {
    uint256 vaultSupply = token.balanceOf(vaultERC20);
    uint256 allowance = token.allowance(vaultERC20, address(this));
    return (vaultSupply < allowance) ? vaultSupply : allowance;
  }
 
  /* Investor specific attributes */
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].unspentETH;
  }

  function investorInvestedCHF(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].investedCHF;
  }

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool)
  {
    return investors[_investorId].acceptedSPA;
  }

  function investorAllocations(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].allocations;
  }

  function investorTokens(uint256 _investorId) public view returns (uint256) {
    return investors[_investorId].tokens;
  }

  function investorCount() public view returns (uint256) {
    return investorCount;
  }

  function investorLimit(uint256 _investorId) public view returns (uint256) {
    return investorLimits[_investorId];
  }

  /**
   * @dev minimal balance
   */
  function minimalAutoWithdraw() public view returns (uint256) {
    return MINIMAL_AUTO_WITHDRAW;
  }

  /**
   * @dev minimal balance
   */
  function minimalBalance() public view returns (uint256) {
    return minimalBalance;
  }

  /**
   * @dev minimal balance
   */
  function basePriceCHFCent() public view returns (uint256) {
    return BASE_PRICE_CHF_CENT;
  }

  /**
   * @dev contributionLimit
   */
  function contributionLimit(uint256 _investorId) public view returns (uint256) {
    uint256 kycLevel = userRegistry.extended(_investorId, KYC_LEVEL_KEY);
    uint256 limit = 500;
    if(kycLevel == 1) {
      limit = 5000;
    } else if (kycLevel == 2) {
      limit = 15000;
    } else if (kycLevel == 3) {
      limit = 100000;
    } else if (kycLevel >= 4) {
      limit = 250000;
    } else {
      limit = investorLimits[_investorId];
    }
    return limit.sub(investors[_investorId].investedCHF);
  }

  /**
   * @dev updateMinimalBalance
   */
  function updateMinimalBalance(uint256 _minimalBalance) public returns (uint256) {
    minimalBalance = _minimalBalance;
  }

  /**
   * @dev define investor limit
   */
  function defineInvestorLimit(uint256 _investorId, uint256 _limit)
    public returns (uint256) {
    investorLimits[_investorId] = _limit;
  }

  /* Share Purchase Agreement */
  /**
   * @dev define SPA
   */
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public onlyOwner returns (bool)
  {
    sharePurchaseAgreementHash = _sharePurchaseAgreementHash;
    emit SalePurchaseAgreementHash(_sharePurchaseAgreementHash);
  }

  /**
   * @dev Accept SPA and invest if msg.value > 0
   */
  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public beforeSaleIsClosed payable returns (bool)
  {
    require(
      _sharePurchaseAgreementHash == sharePurchaseAgreementHash, "TOS06");
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId > 0, "TOS07");
    investors[investorId].acceptedSPA = true;
    investorCount++;

    if (msg.value > 0) {
      investETH();
    }
  }

  /* Investment */
  function investETH() public saleIsOpened payable {
    //Accepting SharePurchaseAgreement is temporarily offchain
    //uint256 investorId = userRegistry.userId(msg.sender);
    //require(investors[investorId].acceptedSPA, "TOS08");
    investInternal(msg.sender, msg.value, 0);
    autoWithdrawETHFunds();
  }

  /**
   * @dev add off chain investment
   */
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public onlyAuthority
  {
    investInternal(_investor, 0, _amountCHF);
  }

  /* Schedule */ 
  /**
   * @dev update schedule
   */
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public onlyAuthority beforeSaleIsOpened
  {
    require(_startAt < _endAt, "TOS09");
    startAt = _startAt;
    endAt = _endAt;
  }

  /* Allocations admin */
  /**
   * @dev allocate
   */
  function allocateTokens(address _investor, uint256 _amount)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    uint256 investorId = userRegistry.userId(_investor);
    require(investorId > 0, "TOS10");
    Investor storage investor = investors[investorId];
    
    allocatedTokens = allocatedTokens.sub(investor.allocations).add(_amount);
    require(allocatedTokens <= availableSupply(), "TOS11");

    investor.allocations = _amount;
    emit Allocation(investorId, _amount);
  }

  /**
   * @dev allocate many
   */
  function allocateManyTokens(address[] _investors, uint256[] _amounts)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    require(_investors.length == _amounts.length, "TOS12");
    for (uint256 i = 0; i < _investors.length; i++) {
      allocateTokens(_investors[i], _amounts[i]);
    }
  }

  /* ETH administration */
  /**
   * @dev fund ETH
   */
  function fundETH() public payable onlyAuthority {
    emit FundETH(msg.value);
  }

  /**
   * @dev refund unspent ETH many
   */
  function refundManyUnspentETH(address[] _receivers) public onlyAuthority {
    for(uint256 i = 0; i < _receivers.length; i++) {
      refundUnspentETH(_receivers[i]);
    }
  }

  /**
   * @dev refund unspent ETH
   */
  function refundUnspentETH(address _receiver) public onlyAuthority {
    uint256 investorId = userRegistry.userId(_receiver);
    require(investorId != 0, "TOS13");
    Investor storage investor = investors[investorId];

    if (investor.unspentETH > 0) {
      // solium-disable-next-line security/no-send
      require(_receiver.send(investor.unspentETH), "TOS14");
      totalRefundedETH = totalRefundedETH.add(investor.unspentETH);
      emit WithdrawETH(_receiver, investor.unspentETH);
      totalUnspentETH = totalUnspentETH.sub(investor.unspentETH);
      investor.unspentETH = 0;
    }
  }

  /**
   * @dev withdraw ETH funds
   */
  function withdrawETHFunds() public onlyAuthority {
    uint256 balance = address(this).balance;
    if (balance > minimalBalance.add(totalUnspentETH)) {
      uint256 amount = balance.sub(minimalBalance);
      // solium-disable-next-line security/no-send
      require(vaultETH.send(amount), "TOS15");
      emit WithdrawETH(vaultETH, amount);
    }
  }

  /**
   * @dev withdraw all ETH funds
   */
  function withdrawAllETHFunds() public onlyAuthority {
    uint256 balance = address(this).balance;
    // solium-disable-next-line security/no-send
    require(vaultETH.send(balance), "TOS15");
    emit WithdrawETH(vaultETH, balance);
  }

  /**
   * @dev auto withdraw ETH funds
   */
  function autoWithdrawETHFunds() private {
    uint256 balance = address(this).balance;
    if (balance >= minimalBalance.add(MINIMAL_AUTO_WITHDRAW)) {
      uint256 amount = balance.sub(minimalBalance);
      // solium-disable-next-line security/no-send
      if (vaultETH.send(amount)) {
        emit WithdrawETH(vaultETH, amount);
      }
    }
  }

  /**
   * @dev invest internal
   */
  function investInternal(
    address _investor, uint256 _amountETH, uint256 _amountCHF)
    private
  {
    // investment with _amountETH is decentralized
    // investment with _amountCHF is centralized
    // They are mutually exclusive
    require((_amountETH != 0 && _amountCHF == 0) ||
      (_amountETH == 0 && _amountCHF != 0), "TOS16");

    require(ratesProvider.rateWEIPerCHFCent() != 0, "TOS17");
    uint256 investorId = userRegistry.userId(_investor);
    require(userRegistry.isValid(investorId), "TOS18");

    Investor storage investor = investors[investorId];

    uint256 contributionCHF = ratesProvider.convertWEIToCHFCent(
      investor.unspentETH);

    if (_amountETH > 0) {
      contributionCHF = contributionCHF.add(
        ratesProvider.convertWEIToCHFCent(_amountETH));
    }
    if (_amountCHF > 0) {
      contributionCHF = contributionCHF.add(_amountCHF);
    }

    if (contributionCHF < contributionLimit(investorId)) {
      uint256 tokens = contributionCHF.div(BASE_PRICE_CHF_CENT);
      uint256 availableTokens = availableSupply().sub(
        allocatedTokens).add(investor.allocations);
      require(availableTokens != 0, "TOS19");

      if (tokens > availableTokens) {
        tokens = availableTokens;
      }
    }

    /** Calculating unspentETH value **/
    uint256 investedCHF = tokens.mul(BASE_PRICE_CHF_CENT);
    uint256 unspentContributionCHF = contributionCHF.sub(investedCHF);

    uint256 unspentETH = 0;
    if (unspentContributionCHF != 0) {
      if (_amountCHF > 0) {
        // Prevent CHF investment LARGER than available supply
        // from creating a too large and dangerous unspentETH value
        require(unspentContributionCHF < BASE_PRICE_CHF_CENT, "TOS20");
      }
      unspentETH = ratesProvider.convertCHFCentToWEI(
        unspentContributionCHF);
    }

    /** Spent ETH **/
    uint256 spentETH = 0;
    if (investor.unspentETH == unspentETH) {
      spentETH = _amountETH;
    } else {
      uint256 unspentETHDiff = (unspentETH > investor.unspentETH)
        ? unspentETH.sub(investor.unspentETH)
        : investor.unspentETH.sub(unspentETH);

      if (_amountCHF > 0) {
        if (unspentETH < investor.unspentETH) {
          spentETH = unspentETHDiff;
        }
        // if unspentETH > investor.unspentETH
        // then CHF has been converted into ETH
        // and no ETH were spent
      }
      if (_amountETH > 0) {
        spentETH = (unspentETH > investor.unspentETH)
          ? _amountETH.sub(unspentETHDiff)
          : _amountETH.add(unspentETHDiff);
      }
    }

    totalUnspentETH =
      totalUnspentETH.sub(investor.unspentETH).add(unspentETH);
    investor.unspentETH = unspentETH;
    investor.investedCHF = investor.investedCHF.add(investedCHF);
    investor.tokens = investor.tokens.add(tokens);
    raisedCHF = raisedCHF.add(_amountCHF);
    raisedETH = raisedETH.add(spentETH);
    totalRaisedCHF = totalRaisedCHF.add(investedCHF);

    allocatedTokens = allocatedTokens.sub(investor.allocations);
    investor.allocations = (investor.allocations > tokens)
      ? investor.allocations.sub(tokens) : 0;
    allocatedTokens = allocatedTokens.add(investor.allocations);
    require(
      token.transferFrom(vaultERC20, _investor, tokens),
      "TOS21");

    if (spentETH > 0) {
      emit ChangeETHCHF(
        _investor,
        spentETH,
        ratesProvider.convertWEIToCHFCent(spentETH),
        ratesProvider.rateWEIPerCHFCent());
    }
    emit Investment(investorId, investedCHF);
  }

  /* Util */
  /**
   * @dev current time
   */
  function currentTime() private view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return now;
  }
}
