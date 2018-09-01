pragma solidity ^0.4.24;

import "../zeppelin/token/ERC20/ERC20.sol";
import "../zeppelin/ownership/Ownable.sol";
import "../zeppelin/math/SafeMath.sol";
import "./Shareholder.sol";


/**
 * @title DemoShare
 * @dev DemoShare contract
 *
 * Voting mechanism to distribute shares
 *
 * @author Cyril Lapinte - <cyril.lapinte@mtpelerin.com>
 *
 * Error messages
 * E01: Previous vote must be closed
 * E02: Current vote must be open
 * E03: Participant has already voted
 * E04: Participant has no tokens
 * E05: Current vote must be closed
 * E06: Cannot distribute more ETH than available
*/
contract DemoShare is Shareholder {
  using SafeMath for uint256;
  uint256 constant UINT256_MAX = ~uint256(0);

  struct Proposal {
    string url;
    uint256 hash;
    ERC20 dividendToken;
    uint256 startedAt;
    uint256 closedAt;
    uint256 approvals;
    uint256 rejections;
  }
  Proposal internal currentProposal;

  mapping(uint256 => mapping(address => bool)) participants;
  uint256 internal proposalCount;

  ERC20 public token;

  /**
   * @dev constructor
   **/
  constructor(ERC20 _token) public {
    token = _token;
  }

  /**
   * @dev token
   */
  function token() public view returns (ERC20) {
    return token;
  }

  /**
   * @dev update token
   */
  function updateToken(ERC20 _token) public onlyOwner {
    token = _token;
  }

  /**
   * @dev current proposal id
   */
  function currentProposalId() public view returns (uint256) {
    return proposalCount;
  }

  /**
   * @dev current proposal url
   */
  function currentUrl() public view returns (string) {
    return currentProposal.url;
  }

  /**
   * @dev current proposal hash
   */
  function currentHash() public view returns (uint256) {
    return currentProposal.hash;
  }

  /**
   * @dev current proposal dividend token
   */
  function currentDividendToken() public view returns (ERC20) {
    return currentProposal.dividendToken;
  }

  /**
   * @dev current proposal started at
  */
  function startedAt() public view returns (uint256) {
    return currentProposal.startedAt;
  }

  /**
   * @dev current proposal closed at
   */
  function closedAt() public view returns (uint256) {
    return currentProposal.closedAt;
  }

  /**
   * @dev current proposal approvals
   */
  function voteApprovals() public view returns (uint256) {
    return currentProposal.approvals;
  }

  /**
   * @dev current proposal rejections
   */
  function voteRejections() public view returns (uint256) {
    return currentProposal.rejections;
  }

  /**
   * @dev current proposal hasVoted
   */
  function hasVoted(address _address) public view returns (bool) {
    return participants[proposalCount][_address];
  }

  /**
   * @dev propose a new vote. Owner only
   */
  function proposeVote(
    string _url,
    uint256 _hash,
    ERC20 _dividendToken) public onlyOwner
  {
    require(currentProposal.closedAt < currentTime(), "E01");

    if (proposalCount > 0) {
      delete currentProposal;
    }
    currentProposal = Proposal(
      _url,
      _hash,
      _dividendToken,
      currentTime(),
      UINT256_MAX,
      0,
      0
    );
    emit NewProposal(proposalCount);
  }

  /**
   * @dev close the current vote. Owner only
   */
  function closeVote() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "E02");
 
    //ERC20 dividendToken = currentProposal.dividendToken;
    //uint256 balance = dividendToken.balanceOf(this);
    uint256 totalSupply = token.totalSupply();

    if ((2*currentProposal.approvals) > totalSupply) {
//     if (distributeInternal(balance, dividendToken, shareholders)) {
      emit Approved(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
      currentProposal.closedAt = currentTime();
     //}
    } else {
//      if (balance == 0 || dividendToken.transfer(owner, balance)) {
      emit Rejected(
        proposalCount,
        totalSupply,
        currentProposal.approvals,
        currentProposal.rejections
      );
      currentProposal.closedAt = currentTime();
    // }
    }
  }

  /**
   * @dev close the current if approval. Owner only
   */
  function closeVoteApproval() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "E02");
    uint256 totalSupply = token.totalSupply();

    emit Approved(
      proposalCount,
      totalSupply,
      currentProposal.approvals,
      currentProposal.rejections
    );
    currentProposal.closedAt = currentTime();
  }

  /**
   * @dev close the current vote. Owner only
   */
  function closeVoteRejection() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "E02");
    uint256 totalSupply = token.totalSupply();

    emit Rejected(
      proposalCount,
      totalSupply,
      currentProposal.approvals,
      currentProposal.rejections
    );
    currentProposal.closedAt = currentTime();
  }

  /**
   * @dev close the current vote. Owner only
   */
  function forceCloseVoteNoActions() public onlyOwner {
    require(currentProposal.closedAt > currentTime(), "E02");
    currentProposal.closedAt = currentTime();
    proposalCount++;
  }

  /**
   * @dev approve the current vote
   */
  function approveProposal() public {
    require(currentProposal.closedAt > currentTime(), "E02");
    require(!participants[proposalCount][msg.sender], "E03");
    uint256 balance = token.balanceOf(msg.sender);
    require(balance > 0, "E04");

    if (proposalCount > 0) {
      delete participants[proposalCount-1][msg.sender];
    }
 
    currentProposal.approvals = currentProposal.approvals.add(balance);
    participants[proposalCount][msg.sender] = true;
  }

  /**
   * @dev reject the current vote
   */
  function rejectProposal() public {
    require(!participants[proposalCount][msg.sender], "E03");
    uint256 balance = token.balanceOf(msg.sender);
    require(balance > 0, "E04");

    if (proposalCount > 0) {
      delete participants[proposalCount-1][msg.sender];
    }

    currentProposal.rejections = currentProposal.rejections.add(balance);
    participants[proposalCount][msg.sender] = true;
  }

  /**
   * @dev Distribute token dividend
   */
  function distribute() public onlyOwner returns (bool) {
    require(currentProposal.closedAt <= currentTime(), "E05");
    
    ERC20 dividendToken = currentProposal.dividendToken;
    uint256 balance = dividendToken.balanceOf(this);
    distributeInternal(balance, dividendToken, shareholders);
    proposalCount++;
    return true;
  }

  /**
   * @dev Distribute special dividend
   */
  function distributeSpecial(
    uint256 _dividendAmount,
    ERC20 _token, address[] _addresses) public onlyOwner returns (bool)
  {
    return distributeInternal(_dividendAmount, _token, _addresses);
  }

  /**
   * @dev distribute internal
   */
  function distributeInternal(
    uint256 _dividendAmount,
    ERC20 _token, address[] _addresses) internal returns (bool)
  {
    uint256 balance = _token.balanceOf(this);
    require(balance >= _dividendAmount, "E06");

    for (uint256 i = 0; i < _addresses.length; i++) {
      uint256 value = _dividendAmount.mul(
        token.balanceOf(_addresses[i])).div(token.totalSupply()
      );
      if (value > 0) {
        _token.transfer(_addresses[i], value);
      }
    }

    emit Distribution(proposalCount, address(_token), _dividendAmount);
    return true;
  }

  /**
   * @dev currentTime
   */
  function currentTime() internal view returns (uint256) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp;
  }

  event NewProposal(uint256 proposalId);
  event Approved(
    uint256 proposalId,
    uint256 total,
    uint256 approvals,
    uint256 rejections
  );
  event Rejected(
    uint256 proposalId,
    uint256 total,
    uint256 approvals,
    uint256 rejections
  );
  event Distribution(
    uint256 proposalId,
    address token,
    uint256 dividendAmount
  );
}
