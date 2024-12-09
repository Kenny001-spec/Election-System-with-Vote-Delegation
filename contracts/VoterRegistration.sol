// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract VoterRegistration {
    enum ContractState { None, Created, Active, Closed }
    
    ContractState public currentState;

    struct Voter {
        string name;
        bool isEligible;
    }

    mapping(address => Voter) public voterRegistry;
    address[] public registeredVoters;
    address[] public electoralBoardMembers;

    modifier onlyElectoralBoard() {
        require(isElectoralBoardMember(msg.sender), "Only electoral board members can perform this action.");
        _;
    }

    modifier onlyDuringActive() {
        require(currentState == ContractState.Active, "The voter registration is not active.");
        _;
    }

    constructor() {
        currentState = ContractState.Created;
    }

    function registerVoter(address _voterAddress, string memory _name) public onlyElectoralBoard onlyDuringActive {
        require(!isVoterRegistered(_voterAddress), "Voter is already registered.");
        voterRegistry[_voterAddress] = Voter(_name, true);
        registeredVoters.push(_voterAddress);
    }

    function isVoterRegistered(address _voterAddress) public view returns (bool) {
        return voterRegistry[_voterAddress].isEligible;
    }

    function addElectoralBoardMember(address _member) public onlyElectoralBoard {
        electoralBoardMembers.push(_member);
    } 

    function isElectoralBoardMember(address _member) public view returns (bool){

        for (uint256 i = 0; i < electoralBoardMembers.length; i++) {
            if (electoralBoardMembers[i] == _member) {
                return true;
            }
        }
        return false;

    }

    function startVoterRegistration() public onlyElectoralBoard {
        require(currentState == ContractState.Created, "Voter registration has already started.");
        currentState = ContractState.Active;
    }

    function closeVoterRegistration() public onlyElectoralBoard {
        require(currentState == ContractState.Active, "Voter registration is not active.");
        currentState = ContractState.Closed;
    }  
}
