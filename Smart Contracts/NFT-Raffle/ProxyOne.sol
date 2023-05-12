//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ProxyBase.sol"; 
import "./Interfaces/IERC721.sol";

//Create Raffle Function and Enter Raffle Function:

contract ProxyOne is ProxyBase {

    //Helpers: -------------------------------------------

    function generateID (uint256 _hashHelp) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.prevrandao, block.gaslimit, _hashHelp)); 
    }

    function testStrings (string calldata _str, uint256 _min, uint256 _max) internal pure returns (bool) {
        return bytes(_str).length >= _min && bytes(_str).length <= _max; 
    }

    function setTokenInRaffle (bool _option, address[] calldata _tokenContracts, uint256[] calldata _tokenIDs) internal {

        for (uint i = 0; i < _tokenContracts.length; i++) {
            TokenInRaffle[_tokenContracts[i]][_tokenIDs[i]] = _option; 
        }
    }

    function testTokens (address[] calldata _tokenContracts, uint256[] calldata _tokenIDs) internal view returns (bool) {

        require (_tokenContracts.length == _tokenIDs.length && _tokenContracts.length <= 5,
            "Imabalanced parameters or max token limit exceeded"
        ); 

        for (uint i = 0; i < _tokenContracts.length; i++) {

            uint256 currentToken = _tokenIDs[i]; 
            IERC721 currentContract = IERC721(_tokenContracts[i]); 

            if (currentContract.ownerOf(currentToken) != msg.sender || currentContract.getApproved(currentToken) != address(this)) {
                return false; 
            }

            if (TokenInRaffle[address(currentContract)][currentToken]) {
                return false;
            }
        }

        return true; 
    }  

    //Primary Functions: ---------------------------------

    function createRaffle (string[] calldata _nameDesc, address[] calldata _tokenContracts, uint256[] calldata _tokenIDs, uint256[] calldata _numSettings, bool[] calldata _boolSettings) external {

        require (testStrings(_nameDesc[0], 5, 500) && testStrings(_nameDesc[1], 5, 500), 
            "Invalid name or description"
        ); 

        require (_tokenContracts.length <= 5 && _tokenIDs.length <= 5,
            "Token maximum (5) exceeded"
        ); 

        require (testTokens(_tokenContracts, _tokenIDs),
            "Invalid ownership, contract operatorship, or preoccupied tokens"
        ); 

        bytes32 ID = generateID(0); 
        Raffle storage raffle = IDToRaffle[ID];

        raffle.ID = ID;
        raffle.owner = msg.sender;
        raffle.name = _nameDesc[0];
        raffle.description = _nameDesc[1];
        raffle.tokenIDs = _tokenIDs;
        raffle.tokenContracts = _tokenContracts;
        raffle.ticketPrice = _numSettings[0];
        raffle.ticketSupply = _numSettings[1];
        raffle.ticketsPerMember = _numSettings[2];
        
        raffle.isWhitelist = _boolSettings[0];
        raffle.isWinnerTakesAll = _boolSettings[1]; 
        raffle.status = RaffleStatus.Active; 

        setTokenInRaffle (true, _tokenContracts, _tokenIDs); RaffleIDs.push(ID);
        emit RaffleCreated (ID, _nameDesc, _tokenContracts, _tokenIDs, _numSettings, _boolSettings, block.timestamp);
    }

    //----------------------------------------------------

    function enterRaffle (bytes32 _raffleID, uint256 _amount) external payable {

        Raffle storage raffle = IDToRaffle[_raffleID];

        require (raffle.ticketSupply >= _amount, "Insufficient supply");
        require (raffle.ticketPrice * _amount == msg.value, "Insufficient funds"); 
        require (raffle.owner != msg.sender, "Owners can not enter their own raffles"); 

        require (raffle.ticketsPerMember >= raffle.MemberToTicketIDs[msg.sender].length + _amount,
            "Personal ticket limit exceeded"
        ); 

        if (raffle.isWhitelist) {

            require (raffle.IsWhitelisted[msg.sender],
                "Unauthorized, you are not whitelisted"
            ); 
        }

        if (raffle.MemberToTicketIDs[msg.sender].length < 1) { 
            raffle.members.push(msg.sender); 
        }

        for (uint i = 0; i < _amount; i++) { bytes32 ID = generateID(i); 

            raffle.ticketIDs.push(ID);
            raffle.TicketIDToMember[ID] = msg.sender;
            raffle.MemberToTicketIDs[msg.sender].push(ID); 
        }

        raffle.funds += msg.value; 
        emit RaffleEntered (_raffleID, _amount, msg.sender, msg.value, block.timestamp);
    }
}