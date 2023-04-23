// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DAO {
    address public admin;
    address public token;
    uint256 public minTokens;
    mapping(address => bool) public members;
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCounter;

    struct Proposal {
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        bool executed;
        mapping(address => bool) voters;
    }

    event MemberAdded(address indexed member);
    event ProposalSubmitted(uint256 indexed id, address indexed proposer, string description);
    event Voted(uint256 indexed id, address indexed voter, bool inSupport);
    event ProposalExecuted(uint256 indexed id);

    constructor(address _admin, address _token, uint256 _minTokens) {
        admin = _admin;
        token = _token;
        minTokens = _minTokens;
    }

    function addMember(address member) external {
        require(msg.sender == admin, "Only admin can add members");
        require(!members[member], "Member already exists");
        require(IToken(token).balanceOf(member) >= minTokens, "Insufficient tokens to join DAO");
        members[member] = true;
        emit MemberAdded(member);
    }

    function submitProposal(string calldata description) external returns (uint256) {
        require(members[msg.sender], "Only members can submit proposals");
        uint256 id = ++proposalCounter;
        Proposal storage newProposal = proposals[id];
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.votesFor = 0;
        newProposal.votesAgainst = 0;
        newProposal.executed = false;
        emit ProposalSubmitted(id, msg.sender, description);
        return id;
    }

    function vote(uint256 id, bool inSupport) external {
        require(members[msg.sender], "Only members can vote");
        require(!proposals[id].voters[msg.sender], "Cannot vote twice on same proposal");
        require(!proposals[id].executed, "Proposal has already been executed");

        proposals[id].voters[msg.sender] = true;
        if (inSupport) {
            proposals[id].votesFor++;
        } else {
            proposals[id].votesAgainst++;
        }
        emit Voted(id, msg.sender, inSupport);
    }

    function executeProposal(uint256 id) external {
        require(proposals[id].votesFor > proposals[id].votesAgainst, "Proposal was not approved");
        require(!proposals[id].executed, "Proposal has already been executed");

        proposals[id].executed = true;
        IToken(token).transfer(proposals[id].proposer, minTokens);
        emit ProposalExecuted(id);
    }

    // LitAction to automate adding a new member to the DAO
    function addMemberLitAction(address member) external {
        bytes memory data = abi.encodeWithSignature("addMember(address)", member);
        bytes memory context = abi.encode(msg.sender);
        ILit lit = ILit(0xB17D999E840D9B4d4a4E0F87B912C4cb449d9709);
        lit.submitTransaction(address(this), 0, data, context);
    }
}

interface IToken {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ILit {
    function submitTransaction(address to, uint256 value, bytes calldata data, bytes calldata context) external returns (bytes32);
}
