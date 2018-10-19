pragma solidity ^0.4.24;

import "../interface/IUserRegistry.sol";
import "../interface/ITokensale.sol";
import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/math/SafeMath.sol";
import "../Authority.sol";


/**
 * @title Tokensale
 * @dev Tokensale interface
 *
 * !!!! WARNING: NOT YET TESTED !!!!
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
 * TOS01:
 * TOS02:
 * TOS03:
 * TOS04:
 * TOS05:
 * TOS06:
 * TOS07:
 * TOS08:
 * TOS09:
 * TOS10:
 * TOS11:
 * TOS12:
 * TOS13:
 * TOS14:
 * TOS15:
 */
contract Tokensale is ITokensale, Authority {
  using SafeMath for uint256;

  // Minimal Auto Withdraw must be allow the nominal price
  // to ensure enough remains on the balance to refund the investors
  uint256 constant MINIMAL_AUTO_WITHDRAW = 5 * 10 ** 17;

  uint256 constant NOMINAL_PRICE_CHF_CENT = 500;

  /* General sale details */
  ERC20 public token;
  address public vaultETH;
  address public vaultERC20;
  IUserRegistry public userRegistry;
  bytes32 public sharePurchaseAgreementHash;

  // WEICHF rate is in ETH_wei/CHF_cents with no fractional parts
  uint256 public rateWEIPerCHFCent;

  uint256 public startAt;
  uint256 public endAt;
  uint256 public raisedETH;
  uint256 public raisedCHF;
  uint256 public totalRaisedCHF;
  uint256 public refundedETH;
  uint256 public allocatedTokens;

  struct Investor {
    uint256 unspentETH;
    uint256 depositCHF;
    bool acceptedSPA;
    uint256 allocations;
    uint256 tokens;
  }
  mapping(uint256 => Investor) investors;
  uint256 public investorCount;

  /**
   * @dev Throws if sale is not open
   */
  modifier beforeSaleIsOpened {
    require(currentTime() < startAt, "T0S01");
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
    require(currentTime() <= endAt, "T0S03");
    _;
  }
 
  /**
   * @dev constructor
   */
  constructor(ERC20 _token, address _vaultERC20, address _vaultETH) public {
    startAt = ~uint256(0);
    endAt =  ~uint256(0);

    token = _token;
    vaultERC20 = _vaultERC20;
    vaultETH = _vaultETH;
  }

  /**
   * @dev fallback function
   */
  function () external payable {
    require(msg.data.length == 0, "TOS04");
    investETH();
  }

  /**
   * @dev convert rate from ETHCHF to WEICents
   */
  function convertRateFromETHCHF(
    uint256 _rateETHCHF,
    uint256 _rateETHCHFDecimal
  ) public pure returns (uint256) {
    if (_rateETHCHF == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateETHCHF);
  }

  /**
   * @dev convert rate from WEICents to ETHCHF
   */
  function convertRateToETHCHF(
    uint256 _rateWEIPerCHFCent,
    uint256 _rateETHCHFDecimal) public pure returns (uint256) {
    if (_rateWEIPerCHFCent == 0) {
      return 0;
    }

    return uint256(
      10**(_rateETHCHFDecimal.add(18 - 2))
    ).div(_rateWEIPerCHFCent);
  }

  /**
   * @dev convert CHF to ETH
   */
  function convertCHFCentToWEI(uint256 _amountCHF)
    public view returns (uint256) {
    if (rateWEIPerCHFCent == 0) {
      return 0;
    }

    return _amountCHF.mul(rateWEIPerCHFCent);
  }

  /**
   * @dev convert ETH to CHF
   */
  function convertWEItoCHFCent(uint256 _amountETH)
    public view returns (uint256) {
    if (rateWEIPerCHFCent == 0) {
      return 0;
    }

    return _amountETH.div(rateWEIPerCHFCent);
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

  function refundedETH() public view returns (uint256) {
    return refundedETH;
  }
 
  /* Investor specific attributes */
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].unspentETH;
  }

  function investorDepositCHF(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].depositCHF;
  }

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool) {
    return investors[_investorId].acceptedSPA;
  }

  function investorAllocations(uint256 _investorId)
    public view returns (uint256) {
    return investors[_investorId].allocations;
  }

  function investorTokens(uint256 _investorId) public view returns (uint256) {
    return investors[_investorId].tokens;
  }

  function investorCount() public view returns (uint256) {
    return investorCount;
  }

  /* Current ETHCHF rates */
  function rateWEIPerCHFCent() public view returns (uint256);
  
  /**
   * @dev rate ETHCHF
   */
  function rateETHCHF(uint256 _rateETHCHFDecimal)
    public view returns (uint256)
  {
    return convertToETHCHF(rateWEIPerCHFCent, _rateETHCHFDecimal);
  }

  /* Share Purchase Agreement */
  /**
   * @dev define SPA
   */
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public onlyOwner returns (bool) {
    sharePurchaseAgreementHash = _sharePurchaseAgreementHash;
    emit SalePurchaseAgreementHash(_sharePurchaseAgreementHash);
  }

  /**
   * @dev Accept SPA and invest if msg.value > 0
   */
  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public beforeSaleIsClosed payable returns (bool) {
    require(
      _sharePurchaseAgreementHash == sharePurchaseAgreementHash, "TOS05");
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId > 0, "TOS06");
    investors[investorId].acceptedSPA = true;
    investorCount++;

    if(msg.value > 0) {
      investETH();
    }
  }

  /* Investment */
  function investETH() public saleIsOpened payable {
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investors[investorId].acceptedSPA, "TOS07");
    invest(msg.sender, msg.value, 0);
    autoWithdrawETHFunds();
  }

  /**
   * @dev add off chain investment
   */
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public onlyAuthority
  {
    invest(_investor, 0, _amountCHF);
  }
  
  /**
   * @dev invest 
   */
  function invest(address _investor, uint256 _amountETH, uint256 _amountCHF)
    private beforeSaleIsClosed
  {
    uint256 investorId = userRegistry.userId(_investor);
    require(userRegistry.isValid(investorId), "TOS08");

    Investor storage investor = investors[investorId];

    uint256 contributionCHF = investor.unspentETH.div(rateWEIPerCHFCent);
    if (_amountETH > 0) {
      contributionCHF = contributionCHF.add(
        _amountETH.div(rateWEIPerCHFCent));
    }
    if (_amountCHF > 0) {
      contributionCHF = contributionCHF.add(_amountCHF);
    }

    if (contributionCHF > NOMINAL_PRICE_CHF_CENT) {
      uint256 tokens = contributionCHF.div(NOMINAL_PRICE_CHF_CENT);
      uint256 availableTokens
        = token.balanceOf(vaultERC20).sub(allocatedTokens);

      if(tokens <= availableTokens) {
        investor.tokens = tokens;
      } else {
        investor.tokens = availableTokens;
      }

      uint256 spentCHF = investor.tokens.mul(NOMINAL_PRICE_CHF_CENT);
      uint256 unspentCHF = (contributionCHF.sub(spentCHF));
      uint256 spentETH = 0;
      if(spentCHF != contributionCHF) {
        if(_amountETH > 0) {
          spentETH
            = spentCHF.sub(_amountCHF).mul(rateWEIPerCHFCent);
          investor.unspentETH
            = investor.unspentETH.add(_amountETH).sub(spentETH);
          assert(investor.unspentETH < _amountETH);
        } else {
          // It must not be expected from a CHF investment
          // Require is preferred over revert as it helps identify the error codes
          require(true, "TOS09");
        }
      }

      investor.depositCHF = investor.depositCHF.add(spentCHF);
      raisedCHF = raisedCHF.add(_amountCHF);
      raisedETH = raisedETH.add(spentETH);
      totalRaisedCHF = totalRaisedCHF.add(spentCHF);
      investor.allocations
        = (investor.allocations > investor.tokens)
          ? investor.allocations.sub(investor.tokens) : 0;
 
      require(token.transferFrom(
        vaultERC20, _investor, investor.tokens), "TOS10");
      if(spentETH > 0) {
        uint256 convertedSpentETH = spentETH.div(rateWEIPerCHFCent);
        emit ChangeETHCHF(
          _investor, spentETH, convertedSpentETH, rateWEIPerCHFCent);
      }
      emit Investment(investorId, spentCHF, unspentCHF);
    }

  }

  /* Schedule */ 
  /**
   * @dev update schedule
   */
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public beforeSaleIsOpened returns (uint256) {
    startAt = _startAt;
    endAt = _endAt;
  }

  /* Allocations admin */
  /**
   * @dev allocate
   */
  function allocate(address _investor, uint256 _amount)
    public onlyAuthority beforeSaleIsClosed returns (bool) {
    uint256 investorId = userRegistry.userId(_investor);
    require(investorId > 0, "TOS11");
    Investor storage investor = investors[investorId];
    
    allocatedTokens
      = allocatedTokens.sub(investor.allocations).add(_amount);
    investor.allocations = _amount;
    emit Allocation(investorId, _amount);
  }

  /**
   * @dev allocate many
   */
  function allocateMany(address[] _investors, uint256[] _amounts)
    public onlyAuthority beforeSaleIsClosed returns (bool) {
    require(_investors.length == _amounts.length, "TOS12");
    for(uint256 i; i < _investors.length; i++) {
      allocate(_investors[i], _amounts[i]);
    }
  }

  /* Rates admin */
  /**
   * @dev define rate
   */
  function defineRate(uint256 _rateWEIPerCHFCent)
    public onlyAuthority
  {
    rateWEIPerCHFCent = _rateWEIPerCHFCent;
    emit Rate(currentTime(), _rateWEIPerCHFCent);
  }

  /**
   * @dev define rate with decimals
   */
  function defineRateWithDecimals(uint256 _rateETHCHF, uint256 _rateETHCHFDecimal)
    public onlyAuthority
  {
    // The rate is inverted to maximize the decimals stored
    defineRate(convertFromETHCHF(_rateETHCHF, _rateETHCHFDecimal));
  }

  /* ETH administration */
  /**
   * @dev refund unspent ETH
   */
  function refundUnspentETH() public {
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId > 0, "TOS13");
    Investor storage investor = investors[investorId];

    if(investor.unspentETH > 0) {
      require(msg.sender.send(investor.unspentETH), "TOS14");
      refundedETH = refundedETH.add(investor.unspentETH);
      emit WithdrawETH(msg.sender, investor.unspentETH);
      investor.unspentETH = 0;
    }
  }

  /**
   * @dev withdraw ETH funds
   */
  function withdrawETHFunds() public onlyAuthority {
    uint256 balance = address(this).balance;
    require(vaultETH.send(balance), "TOS15");
    emit WithdrawETH(vaultETH, balance);
  }

  /**
   * @dev auto withdraw ETH funds
   */
  function autoWithdrawETHFunds() public {
    if (address(this).balance >= MINIMAL_AUTO_WITHDRAW) {
      withdrawETHFunds();
    }
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
