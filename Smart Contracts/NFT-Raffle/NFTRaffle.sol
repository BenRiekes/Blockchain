//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ProxyBase.sol";
import "./ProxyOne.sol";
import "./ProxyTwo.sol";
import "./Interfaces/IVRF.sol";


contract NFTRaffle is ProxyBase {

    constructor (address _VRF) {

        VRF = IVRF(_VRF);
        Proxy1 = address(new ProxyOne());
        Proxy2 = address(new ProxyTwo()); 
    }

    modifier AccessControl (bytes32 _raffleID, bool _onlyOwner) {

        require (IDToRaffle[_raffleID].ID == _raffleID && IDToRaffle[_raffleID].status == RaffleStatus.Active,
            "Invalid ID or inactive raffle query"
        );

        if (_onlyOwner) {

            require (msg.sender == IDToRaffle[_raffleID].owner || msg.sender == address(VRF), 
                "Unauthorized"
            ); 
        }
        _; 
    }

    //Getters: ----------------------------------------------------------

    function getRaffleMembers (bytes32 _raffleID) public view returns (address[] memory members) {
        return IDToRaffle[_raffleID].members;
    }

    function getMemberTickets (bytes32 _raffleID, address _member) public view returns (bytes32[] memory tickets) {
        return IDToRaffle[_raffleID].MemberToTicketIDs[_member];
    }

    function getRaffleTickets (bytes32 _raffleID) public view returns (bytes32[] memory tickets) {
        return IDToRaffle[_raffleID].ticketIDs;
    }

    function getRaffleTokens (bytes32 _raffleID) public view returns (address[] memory contracts , uint256[] memory tokens) {
        return (IDToRaffle[_raffleID].tokenContracts, IDToRaffle[_raffleID].tokenIDs);
    }

    function getTicketHolder (bytes32 _raffleID, bytes32 _ticketID) public view returns (address holder) {
        return IDToRaffle[_raffleID].TicketIDToMember[_ticketID]; 
    }

    function getIsWhitelisted (bytes32 _raffleID, address _member) public view returns (bool whitelisted) {
        return IDToRaffle[_raffleID].IsWhitelisted[_member];
    }


    //Setters: ----------------------------------------------------------

    function editWhitelist (bytes32 _raffleID, bool _option, address[] calldata _members) external AccessControl (_raffleID, true) {

        require (IDToRaffle[_raffleID].isWhitelist, "Raffle is public");

        for (uint i = 0; i < _members.length; i++) {
            IDToRaffle[_raffleID].IsWhitelisted[_members[i]] = _option;
        }

        emit RaffleWhitelist (_raffleID, _members, _option, block.timestamp);
    } 

    //Proxy One ----------------------------------------------------------

    function createRaffle (string[] calldata _nameDesc, address[] calldata _tokenContracts, uint256[] calldata _tokenIDs, uint256[] calldata _numSettings, bool[] calldata _boolSettings) external {

        (bool success, ) = address(Proxy1).delegatecall(

            abi.encodeWithSignature("createRaffle(string[],address[],uint256[],uint256[],bool[])",
                _nameDesc, _tokenContracts, _tokenIDs, _numSettings, _boolSettings
            )
        ); require (success, "Delegate call failed"); 
    }
    
    function enterRaffle (bytes32 _raffleID, uint256 _amount) external payable AccessControl (_raffleID, false) {

        (bool success, ) = address(Proxy1).delegatecall(

            abi.encodeWithSignature("enterRaffle(bytes32,uint256)",
                _raffleID, _amount
            )
        ); require (success, "Delegate call failed"); 
    }

    //Proxy Two: -------------------------------------------------------------

    function startRaffle (bytes32 _raffleID) external AccessControl (_raffleID, true) {

        (bool success, ) = address(Proxy2).delegatecall(

            abi.encodeWithSignature("startRaffle(bytes32)",
                _raffleID
            )
        ); require (success, "Delegate call failed"); 
 
    }

    function cancelRaffle (bytes32 _raffleID) external AccessControl (_raffleID, true) {

        (bool success, ) = address(Proxy2).delegatecall(

            abi.encodeWithSignature("cancelRaffle(bytes32)",
                _raffleID
            )
        ); require (success, "Delegate call failed"); 
    }

    //VRF Calls ----------------------------------------------------------

    function recieveVRF (bytes32 _requestID, uint256[] memory _result) external {

        require (address(VRF) == msg.sender, "VRF Proxy only");

        (bool success, ) = address(Proxy2).delegatecall(

            abi.encodeWithSignature("processRaffle(bytes32,uint256[])",
                RequestIDToRaffleID[_requestID], _result
            )
        ); require (success, "Delegate call failed"); 
    }

}