//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ProxyBase.sol";
import "./Interfaces/IERC721.sol";

//Start Raffle, Process Raffle, and Cancel Raffle functions:

contract ProxyTwo is ProxyBase {

    //Helpers: -------------------------------------------

    function transferFunds (address _to, uint256 _amount) internal returns (bool) {

        (bool success, ) = payable(_to).call{
           value: _amount
        }(""); 

        return success;
    }

    function setTokenInRaffle (bool _option, address[] memory _tokenContracts, uint256[] memory _tokenIDs) internal {

        for (uint i = 0; i < _tokenContracts.length; i++) {
            TokenInRaffle[_tokenContracts[i]][_tokenIDs[i]] = _option; 
        }
    }


    function testTokens (address[] memory _tokenContracts, uint256[] memory _tokenIDs, address _owner) internal view returns (bool) {

        for (uint i = 0; i < _tokenContracts.length; i++) {

            uint256 currentToken = _tokenIDs[i]; 
            IERC721 currentContract = IERC721(_tokenContracts[i]); 

            if (currentContract.ownerOf(currentToken) != _owner || currentContract.getApproved(currentToken) != address(this)) {
                return false; 
            }
        }

        return true; 
    }

    
    //Primary Functions: ---------------------------------

    function startRaffle (bytes32 _raffleID) external {

        Raffle storage raffle = IDToRaffle[_raffleID];

        if (!testTokens (raffle.tokenContracts, raffle.tokenIDs, raffle.owner)) {

            cancelRaffle(_raffleID);
            revert ("Token Transferred or raffle owner revoked operatorship"); 
        }

        require (raffle.ticketIDs.length >= 1, "Insufficient ticket sales");

        uint256 amount = raffle.isWinnerTakesAll ?
            (1) : (raffle.tokenContracts.length)
        ; 

        bytes32 requestID = VRF.requestVRF(
            address(this), amount, 0, raffle.ticketIDs.length - 1, true
        );

        RequestIDs.push(requestID);
        RequestIDToRaffleID[requestID] = _raffleID;
        raffle.status = RaffleStatus.Pending;

        emit RaffleStarted (_raffleID, requestID, amount, block.timestamp); 
    }

    function cancelRaffle (bytes32 _raffleID) public {

        Raffle storage raffle = IDToRaffle[_raffleID];

        if (raffle.funds > 0) {

            for (uint i = 0; i < raffle.members.length; i++) {

                address current = raffle.members[i];

                uint256 amount = (raffle.ticketPrice * 
                    raffle.MemberToTicketIDs[current].length
                ); 

                require (transferFunds(current, amount), "Refund failure");
            }
        }   

        raffle.funds = 0;
        raffle.status = RaffleStatus.Inactive; 
        setTokenInRaffle(false, raffle.tokenContracts, raffle.tokenIDs); 

        emit RaffleCanceled (_raffleID, block.timestamp); 
    }

    function processRaffle (bytes32 _raffleID, uint256[] memory _result) external {

        Raffle storage raffle = IDToRaffle[_raffleID];

        if (!testTokens(raffle.tokenContracts, raffle.tokenIDs, raffle.owner)) {

            cancelRaffle(_raffleID);
            revert ("Token Transferred or raffle owner revoked operatorship");
        }

        require (raffle.tokenContracts.length == _result.length || 
            _result.length == 1, "VRF Error"
        ); 

        address[] memory winners = new address[](_result.length);
        bytes32[] memory winningTickets = new bytes32[](_result.length);

        for (uint i = 0; i < raffle.tokenContracts.length; i++) {

            bytes32 winningTicket = _result.length > 1 ? 
                (raffle.ticketIDs[_result[i]]) : 
                (raffle.ticketIDs[_result[0]])
            ; 

            address winner = raffle.TicketIDToMember
                [winningTicket]
            ; 

            if (raffle.isWinnerTakesAll && i == 0) {
                winners[0] = winner;
                winningTickets[0] = winningTicket;

            } else if (!raffle.isWinnerTakesAll) {
                winners[i] = winner;
                winningTickets[i] = winningTicket;
            }

            IERC721(raffle.tokenContracts[i]).safeTransferFrom(
                raffle.owner, winner, raffle.tokenIDs[i]
            ); 
        }

        if (raffle.funds > 0) {

            require (transferFunds(raffle.owner, raffle.funds), 
                "Payout error"
            ); 
        }

        raffle.funds = 0;
        raffle.status = RaffleStatus.Inactive;
        setTokenInRaffle(false, raffle.tokenContracts, raffle.tokenIDs); 

        emit RaffleEnded (_raffleID, winningTickets, winners, raffle.isWinnerTakesAll, block.timestamp); 
    }   
}