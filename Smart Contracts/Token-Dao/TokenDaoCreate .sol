//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

import "./TokenDaoLib.sol"; 
import "./ITokenDao.sol";
import "./IERC721.sol"; 

contract TokenDaoCreate {
    ITokenDao storageContract; 

    constructor (address _storageContract) {
        storageContract = ITokenDao(_storageContract); 
    }
    
    //---------------------------------------------------

    function createDao (string calldata _name, address _tokenContract, 
        uint256 _propLength, uint256 _maxActiveProps, 
        uint256 _votesPerToken, uint256 _propPassPercent
        
    ) external {
        uint256 oneDay = 1 days; 

        require (TokenDaoLib.testStrings(_name),
            "Insufficient name"
        );

        require (TokenDaoLib.getTokenContractOwner(
            _tokenContract, msg.sender), "Insufficient Contract Ownership"
        ); 


        ITokenDao.Dao memory dao = ITokenDao.Dao({
            ID: TokenDaoLib.createID(), 
            proposalIDs: new bytes32[](0),
            name: _name, 
            creator: msg.sender, 
            members: new address[](0),
            tokenContract: _tokenContract,
            funds: 0,
            propLength: oneDay * _propLength,
            maxActiveProps: _maxActiveProps,
            votesPerToken: _votesPerToken,
            propPassPercent: _propPassPercent
        });

        storageContract.setCreateDao(dao);
    }

    function createProposal (bytes32 _daoID, string calldata _name, string calldata _desc) external {

        require (TokenDaoLib.getUserMembership(storageContract, _daoID, msg.sender),
         "You are not a member"
        ); 

        require (TokenDaoLib.testStrings(_name) && TokenDaoLib.testStrings(_desc), 
            "Insufficient name and / or desctiption"
        ); 

        require (TokenDaoLib.getCanUserPropose(storageContract, msg.sender, _daoID),
            "Too many active proposals"
        ); 

        ITokenDao.Proposal memory proposal = ITokenDao.Proposal({
            ID: TokenDaoLib.createID(),
            daoID: _daoID,
            creator: msg.sender,
            name: _name,
            desc: _desc,
            noVotes: 0,
            yesVotes: 0,
            timestamp: block.timestamp,
            status: ITokenDao.ProposalState.Pending
        });

        storageContract.setCreateProposal(proposal); 
    }
}   