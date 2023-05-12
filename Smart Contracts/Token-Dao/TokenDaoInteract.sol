//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

import "./TokenDaoLib.sol";
import "./ITokenDao.sol";

contract TokenDaoInteract {
    ITokenDao storageContract; 

    constructor (address _storageContract) {
        storageContract = ITokenDao(_storageContract); 
    }

    //---------------------------------------------------

    function vote (bytes32 _proposalID, uint256 _voteNum, bool _voteYes) external {

        ITokenDao.Proposal memory proposal = TokenDaoLib.getProposal(storageContract, _proposalID); 

        require (TokenDaoLib.getUserMembership(
            storageContract, proposal.daoID, msg.sender), "You are not a member"
        );

        require (TokenDaoLib.getUserVotesLeft(storageContract,
            _proposalID, msg.sender ) >= _voteNum, "Insufficient votes remaining"
        );

        require (proposal.creator != msg.sender,
            "Cannot vote for your own proposal"
        ); 

        require (proposal.status == ITokenDao.ProposalState.Pending, 
            "Proposal is not available"
        );

        storageContract.setVoteProposal(_proposalID, msg.sender, _voteNum, _voteYes);
    }   

    //---------------------------------------------------

    function joinLeave (bytes32 _daoID, bool _joinLeave) external {

        ITokenDao.Dao memory dao = TokenDaoLib.getDao(storageContract, _daoID); 
        
        if (_joinLeave) { 

            require (TokenDaoLib.getBalanceOf(dao.tokenContract, msg.sender) >= 1,
             "You do not own this DAO's token"
            );

        } else { 

            require (TokenDaoLib.getUserMembership(storageContract, _daoID, msg.sender),
                "You are not a member"
            ); 
        }

        storageContract.setDaoMembers(TokenDaoLib.manageDaoMembers(
            dao.members, msg.sender, _joinLeave), msg.sender, _daoID, _joinLeave
        ); 
    }

    function donateToDao (bytes32 _daoID) external payable {

        require (TokenDaoLib.getUserMembership(
            storageContract, _daoID, msg.sender), "You are not a member"
        );

        (bool success, ) = payable(address(this)).call {   
            value: msg.value

        }(""); require (success, "Transaction failed");

        storageContract.setDaoFunds(_daoID, msg.value, true);
    }

    function withdrawDaoFunds (bytes32 _daoID, uint256 _percent) external {
        
        ITokenDao.Dao memory dao = TokenDaoLib.getDao(storageContract, _daoID);

        require (dao.creator == msg.sender, "Only the only can withdraw funds");
        require (dao.funds > 0, "No funds to withdraw"); 

        uint256 val = (dao.funds * _percent) / 100; 

        (bool success, ) = payable(msg.sender).call {
            value: val

        }(""); require (success, "Transaction failed");

        storageContract.setDaoFunds(_daoID, val, false);
    }

    function payoutDividends (bytes32 _daoID, uint256 _percent) external {

        ITokenDao.Dao memory dao = TokenDaoLib.getDao(storageContract, _daoID);

        require (dao.creator == msg.sender, "Unauthorized"); 

        uint256[] memory memberVals = TokenDaoLib.calculateDividends(
            _percent, dao
        );

        uint256 totalAmount = 0; 

        for (uint i = 0; i < dao.members.length; i++) {

            (bool success, ) = payable(dao.members[i]).call {
                value: memberVals[i]

            }(""); require (success, "Transaction failed"); 

            totalAmount += memberVals[i]; 
        }

        storageContract.setDaoFunds(_daoID, totalAmount, false);
    }
}