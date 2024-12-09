// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./VoterRegistration.sol";
import "./StateElection.sol";

contract ElectionFactory {
    
    struct ElectionInfo {
        string stateName;
        address electionContract;
        bool isActive;
    }

   
    address public owner;
    VoterRegistration public voterRegistrationContract;
    ElectionInfo[] public deployedElections;
    mapping(string => bool) public stateElectionExists;

   
    event ElectionDeployed(string indexed stateName, address electionContract);
    event CandidatesAdded(address indexed electionContract, uint256 candidateCount);

   
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    constructor(address _voterRegistrationAddress) {
        owner = msg.sender;
        voterRegistrationContract = VoterRegistration(_voterRegistrationAddress);
    }


    function deployElection(string memory _stateName) external onlyOwner returns (address) {
       
        require(!stateElectionExists[_stateName], "Election for this state already exists");

     
        StateElection newElection = new StateElection(
            _stateName, 
            address(this), 
            address(voterRegistrationContract)
        );

       
        ElectionInfo memory electionInfo = ElectionInfo({
            stateName: _stateName,
            electionContract: address(newElection),
            isActive: true
        });

        deployedElections.push(electionInfo);
        stateElectionExists[_stateName] = true;

  
        emit ElectionDeployed(_stateName, address(newElection));

        return address(newElection);
    }


    function addCandidatesToElection(
        address _electionAddress, 
        string[] memory _candidates
    ) external onlyOwner {
      
        require(_electionAddress != address(0), "Invalid election address");
        
       
        StateElection electionContract = StateElection(_electionAddress);

        
        for (uint256 i = 0; i < _candidates.length; i++) {
            electionContract.addCandidate(_candidates[i]);
        }

       
        emit CandidatesAdded(_electionAddress, _candidates.length);
    }

    
    function getAllElections() 
        external 
        view 
        returns (ElectionInfo[] memory) 
    {
        return deployedElections;
    }

 
    function startElection(address _electionAddress) external onlyOwner {
        StateElection electionContract = StateElection(_electionAddress);
        electionContract.startElection();
    }

  
    function endElection(address _electionAddress) external onlyOwner {
        StateElection electionContract = StateElection(_electionAddress);
        electionContract.endElection();
    }
}