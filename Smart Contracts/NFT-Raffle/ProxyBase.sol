//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IVRF.sol";

contract ProxyBase {

    //Data Query: ----------------------------------------------------------

    event RaffleCreated (bytes32 ID, string[] NameDesc, 
        address[] TokenContracts, uint256[] TokenIDs, 
        uint256[] NumSettings, bool[] Boolsettings, uint256 Timestamp
    ); 

    event RaffleEntered (bytes32 ID, uint256 Amount, 
        address Member, uint256 Payed, uint256 Timestamp
    ); 

    event RaffleStarted (bytes32 ID, bytes32 VRFID, 
        uint256 Amount, uint256 Timestamp
    );

    event RaffleEnded (bytes32 ID, bytes32[] WinningTickets, address[] Winners, 
        bool WinnerTakesAll, uint256 Timestamp
    ); 

    event RaffleCanceled (bytes32 ID, 
        uint256 Timestamp
    );

    event RaffleWhitelist (bytes32 ID, address[] Members, 
        bool Option, uint256 Timestamp
    );

    //Data: ----------------------------------------------------------

    enum RaffleStatus {Inactive, Active, Pending}

    struct Raffle {
        bytes32 ID;
        bytes32[] ticketIDs;

        uint256[] tokenIDs;
        address[] members;
        address[] tokenContracts;

        string name;
        string description;
        
        uint256 funds;
        uint256 ticketPrice;
        uint256 ticketSupply;
        uint256 ticketsPerMember;

        address owner;
        bool isWhitelist;
        bool isWinnerTakesAll;

        RaffleStatus status;
        mapping (address => bool) IsWhitelisted;
        mapping (bytes32 => address) TicketIDToMember;
        mapping (address => bytes32[]) MemberToTicketIDs;
    }

    IVRF VRF;
    address public Proxy1;
    address public Proxy2;

    bytes32[] public RaffleIDs;
    bytes32[] public RequestIDs;

    mapping (bytes32 => Raffle) public IDToRaffle;
    mapping (bytes32 => bytes32) public RequestIDToRaffleID;
    mapping (address => mapping (uint256 => bool)) public TokenInRaffle;
}