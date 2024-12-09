// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IVoterRegistration {
    function isVoterRegistered(address _voter) external view returns (bool);
}

contract StateElection {
    enum ElectionState {
        Pending,    
        Ongoing,    
        Completed   
    }

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    struct VoterDelegate {
        address delegatedTo;
        uint256 voteWeight;
        bool hasVoted;
        bool hasDelegated;
    }

    address public factory;
    address public voterRegistrationContract;
    ElectionState public currentState;
    string public stateName;

    Candidate[] public candidates;
    mapping(address => VoterDelegate) public voters;
    
    uint256 public totalVotes;
    Candidate public winner;

    event CandidateAdded(uint256 indexed candidateIndex, string name);
    event VoteDelegated(address indexed voter, address indexed delegate);
    event Voted(address indexed voter, uint256 indexed candidateIndex, uint256 weight);
    event ElectionEnded(string winner, uint256 winningVotes);

    // Modifiers for access control and state management
    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call this function");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(
            IVoterRegistration(voterRegistrationContract).isVoterRegistered(msg.sender), 
            "Voter not registered"
        );
        _;
    }

    modifier inState(ElectionState _state) {
        require(currentState == _state, "Invalid election state");
        _;
    }

    constructor(
        string memory _stateName, 
        address _factory, 
        address _voterRegistrationContract
    ) {
        stateName = _stateName;
        factory = _factory;
        voterRegistrationContract = _voterRegistrationContract;
        currentState = ElectionState.Pending;
    }

    function startElection() external onlyFactory {
        require(candidates.length >= 2, "Not enough candidates");
        currentState = ElectionState.Ongoing;
    }

    function addCandidate(string memory _name) external onlyFactory {
        require(currentState == ElectionState.Pending, "Cannot add candidates after election starts");
        candidates.push(Candidate(_name, 0));
        emit CandidateAdded(candidates.length - 1, _name);
    }

    function delegateVote(address _to) external 
        onlyRegisteredVoter 
        inState(ElectionState.Ongoing)
    {
        VoterDelegate storage sender = voters[msg.sender];
        
        require(!sender.hasVoted, "Voter has already voted");
        require(!sender.hasDelegated, "Voter has already delegated");
        require(_to != msg.sender, "Cannot delegate to self");

        address currentDelegate = _to;
        uint256 delegationChainLength;

     
        while (voters[currentDelegate].delegatedTo != address(0) && 
               delegationChainLength < 5) {  
            currentDelegate = voters[currentDelegate].delegatedTo;
            require(currentDelegate != msg.sender, "Circular delegation detected");
            delegationChainLength++;
        }

        sender.delegatedTo = _to;
        sender.hasDelegated = true;

        VoterDelegate storage delegatee = voters[_to];
        delegatee.voteWeight += 1;

        emit VoteDelegated(msg.sender, _to);
    }

    function vote(uint256 _candidateIndex) external 
        onlyRegisteredVoter 
        inState(ElectionState.Ongoing)
    {
        VoterDelegate storage voter = voters[msg.sender];

        require(!voter.hasVoted, "Voter has already voted");
        require(_candidateIndex < candidates.length, "Invalid candidate");

        uint256 weight = voter.hasDelegated ? 0 : (voter.voteWeight > 0 ? voter.voteWeight : 1);
        
        candidates[_candidateIndex].voteCount += weight;
        voter.hasVoted = true;
        totalVotes += weight;

        emit Voted(msg.sender, _candidateIndex, weight);
    }

    function endElection() external onlyFactory inState(ElectionState.Ongoing) {
        currentState = ElectionState.Completed;
        _determineWinner();
    }

    function _determineWinner() internal {
        uint256 winningVoteCount = 0;
        uint256 winningCandidateIndex = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningCandidateIndex = i;
            }
        }

        winner = candidates[winningCandidateIndex];
        emit ElectionEnded(winner.name, winner.voteCount);
    }

    function getWinner() external view inState(ElectionState.Completed) returns (string memory) {
        return winner.name;
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }
}