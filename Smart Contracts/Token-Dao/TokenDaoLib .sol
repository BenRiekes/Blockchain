//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

import "./ITokenDao.sol";
import "./IERC721.sol"; 

library TokenDaoLib {

    //Functionality:  --------------------------------------------------------------------------

    function testStrings (string memory _string) internal pure returns (bool) {

        uint256 min = 1;
        uint256 max = 500; 
        uint256 indexLength = bytes(_string).length; 
        
        if (indexLength < min || indexLength > max) {
            return false; 
        }

        return true; 
    } 

    function createID() internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.prevrandao)); 
    }

    //Basic: --------------------------------------------------------------------------

    function getDao (ITokenDao _storageContract, bytes32 _daoID) internal view returns (ITokenDao.Dao memory dao) {
        return _storageContract.getDao(_daoID); 
    }       

    function getProposal (ITokenDao _storageContract, bytes32 _proposalID) internal view returns (ITokenDao.Proposal memory proposal) {
        return _storageContract.getProposal(_proposalID); 
    }

    function getUserMembership (ITokenDao _storageContract, bytes32 _daoID, address _user) internal view returns (bool) {
        return _storageContract.getUserToDao(_user, _daoID); 
    }

    function getBalanceOf(address _tokenContract, address _user) internal view returns (uint256) {
        return IERC721(_tokenContract).balanceOf(_user); 
    }

    function getTokenContractOwner (address _tokenContract, address _user) internal view returns (bool) {
        return IERC721(_tokenContract).owner() == _user; 
    }

   
    //Create Multi Call: ------------------------------------------------------------------------------

    function getCanUserPropose (ITokenDao _storageContract, address _user, bytes32 _daoID) internal view returns (bool) {

        uint256 counter; 
        uint256 maxProposals = getDao(_storageContract, _daoID).maxActiveProps; 
        bytes32[] memory userProposals = _storageContract.getUserDaoProposals(_user, _daoID); 

        for (uint i = 0; i < userProposals.length; i++) {

            if (getProposal(_storageContract, userProposals[i]).status == ITokenDao.ProposalState.Pending) {
                counter++; 
            }   
        }

        return counter < maxProposals; 
    }

    //Interact Multi Call: ------------------------------------------------------------------------------

    function getUserVotesLeft (ITokenDao _storageContract, bytes32 _proposalID, address _user) internal view returns (uint256) {

        ITokenDao.Proposal memory proposal = getProposal(
            _storageContract, _proposalID
        ); 

        ITokenDao.Dao memory dao = getDao(
            _storageContract, proposal.daoID
        );

        return (getBalanceOf(dao.tokenContract, _user) * dao.votesPerToken) - _storageContract.getUserProposalVotes(_user, _proposalID); 
    } 

    //---------------------------------------

    function manageDaoMembers (address[] memory _currentMembers, address _member, bool _joinLeave) internal pure returns (address[] memory) {

        uint256 size = _joinLeave ? (_currentMembers.length + 1) : (_currentMembers.length - 1); 

        address[] memory editedMembers = new address[](size); 

        if (_joinLeave) {

            editedMembers[size - 1] = _member; //Set _member at last index

            for (uint i = 0; i < _currentMembers.length; i++) {   
                editedMembers[i] = _currentMembers[i]; 
            }

        } else { uint256 counter = 0; 

            for (uint i = 0; i < _currentMembers.length; i++) {

                if (_currentMembers[i] != _member) {
                    editedMembers[counter] = _currentMembers[i]; 
                    counter++; 
                }
            }
        }
        
        return editedMembers; 
    }   

    //---------------------------------------

    function calculateDividends (uint256 _percent, ITokenDao.Dao memory dao) internal view returns (uint256[] memory) {

        uint256[] memory memberVals = new uint256[](
            dao.members.length
        );

        uint256 totalRoundFunding = (
            dao.funds * _percent
        ) / 100;

        uint256 totalTokens = 0; 
        uint256 fundsPerToken = totalRoundFunding / totalTokens; 

        //------------------------------------------
        
        //Add token balances to the array first
        for (uint i = 0; i < dao.members.length; i++) { 

            uint256 memberBalance = getBalanceOf (
                dao.tokenContract, dao.members[i]
            ); 

            totalTokens += memberBalance; 
            memberVals[i] = memberBalance; 
        }

        //Then multiply by funds per token and replace its value in the index
        for (uint i = 0; i < dao.members.length; i++) {
            memberVals[i] = memberVals[i] * fundsPerToken; 
        }

        return memberVals;
    }
}