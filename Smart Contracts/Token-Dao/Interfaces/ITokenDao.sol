//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19; 

interface ITokenDao {

    enum ProposalState {Pending, Accepted, Rejected}
    
    struct Dao {
        bytes32 ID;
        bytes32[] proposalIDs;

        string name;  
        address creator;
        address[] members; 
        address tokenContract; 

        uint256 funds; 
        uint256 propLength; 
        uint256 maxActiveProps; 
        uint256 votesPerToken;
        uint256 propPassPercent; 
    }

    struct Proposal {
        bytes32 ID; 
        bytes32 daoID;
        address creator; 

        string name;
        string desc; 

        uint256 noVotes; 
        uint256 yesVotes;
        uint256 timestamp;

        ProposalState status; 
    }

    // Primary Getters
    function getDao(bytes32 _daoID) external view returns (Dao memory dao);
    function getUserToDao(address _user, bytes32 _daoID) external view returns (bool);
    function getUserDaoProposals(address _user, bytes32 _daoID) external view returns (bytes32[] memory);
    function getProposal(bytes32 _proposalID) external view returns (Proposal memory proposal);
    function getUserProposalVotes(address _user, bytes32 _proposalID) external view returns (uint256);

    // Setters
    function setCreateDao(Dao memory dao) external;
    function setDaoFunds (bytes32 _daoID, uint256 _amount, bool _addRemove) external;
    function setDaoMembers(address[] memory _editedMembers, address _user, bytes32 _daoID, bool _add) external;
    function setCreateProposal(Proposal memory proposal) external;
    function setVoteProposal(bytes32 _proposalID, address _user, uint256 _amount, bool _voteYes) external;
}