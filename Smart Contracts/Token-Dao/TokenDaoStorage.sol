//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19; 

contract TokenDaoStorage {

    constructor () {
        owner = msg.sender;
    }

    address private owner; 

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

    //------------------------------------------------------------------------

    Dao[] public daos;
    Proposal[] public proposals; 

    mapping (bytes32 => Dao) public IDToDao; 
    mapping (bytes32 => Proposal) public IDToProposal; 

    mapping (address => mapping (bytes32 => bool)) public UserToDao; 
    mapping (address => mapping (bytes32 => bytes32[])) public UserDaoProposals;
    mapping (address => mapping (bytes32 => uint256)) public UserProposalVotes;  

    mapping (address => bool) private onlyCaller;

    //------------------------------------------------------------------------

    modifier accessControl (bytes32 _ID, bool _isDao, bool _isCreation) {

        //require (onlyCaller[msg.sender], "Unatuhorized"); 

        if (!_isCreation) {
            
            if (_isDao) {

                require (IDToDao[_ID].ID == _ID,
                    "Dao does not exist"
                ); 

            } else {

                require (IDToProposal[_ID].ID == _ID,
                    "Proposal does not exist"
                ); 
            }
        }

        _;
    }

    function setCaller (address _caller, bool _add) external {
        require (msg.sender == owner, "Unauthorized"); 
        onlyCaller[_caller] = _add; 
    } 

    //Getters: ------------------------------------------------------------------------

    function getDao (bytes32 _daoID) external view accessControl (_daoID, true, false) returns (Dao memory dao)  {
        return IDToDao[_daoID]; 
    }

    function getUserToDao (address _user, bytes32 _daoID) external view  accessControl (_daoID, true, false) returns (bool) {
        return UserToDao[_user][_daoID]; 
    }

    function getUserDaoProposals (address _user, bytes32 _daoID) external view  accessControl (_daoID, true, false) returns (bytes32[] memory) {
        return UserDaoProposals[_user][_daoID]; 
    }

    function getProposal (bytes32 _proposalID) external view  accessControl (_proposalID, false, false) returns (Proposal memory proposal) {
        return IDToProposal[_proposalID]; 
    }

    function getUserProposalVotes (address _user, bytes32 _proposalID) external view accessControl (_proposalID, false, false) returns (uint256) {
        return UserProposalVotes[_user][_proposalID]; 
    }


    //Setters: ------------------------------------------------------------------------

    function setCreateDao (Dao memory dao) external accessControl (dao.ID, true, true) {
        
        daos.push(dao);
        IDToDao[dao.ID] = dao;
        UserToDao[dao.creator][dao.ID] = true; 
    }

    function setDaoMembers (address[] memory _editedMembers, address _user, bytes32 _daoID, bool _add) external accessControl (_daoID, true, false) {
        IDToDao[_daoID].members = _editedMembers;
        UserToDao[_user][_daoID] = _add; 
    }

    function setDaoFunds (bytes32 _daoID, uint256 _amount, bool _addRemove) external  accessControl (_daoID, true, false) {

        if (_addRemove) {
            IDToDao[_daoID].funds += _amount; 

        } else { IDToDao[_daoID].funds -= _amount; }
    }

    //------------------------------------------------------------------------

    function setCreateProposal (Proposal memory proposal)  accessControl (proposal.ID, false, true) external {
        IDToProposal[proposal.ID] = proposal;

        proposals.push(proposal); 
        IDToDao[proposal.daoID].proposalIDs.push(proposal.ID);  
        UserDaoProposals[proposal.creator][proposal.daoID].push(proposal.ID); 
    }

    function setVoteProposal (bytes32 _proposalID, address _user, uint256 _amount, bool _voteYes) external accessControl (_proposalID, false, false) {

        if (_voteYes) {
            IDToProposal[_proposalID].yesVotes += _amount; 

        } else { IDToProposal[_proposalID].noVotes += _amount; }

        UserProposalVotes[_user][_proposalID] += _amount; 
    }
}