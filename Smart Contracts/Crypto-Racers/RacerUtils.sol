//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17; 

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721URIStorage.sol";


contract RacerUtils is ERC721URIStorage {
    using Counters for Counters.Counter; 
    Counters.Counter public _tokenIds;


    constructor (address _racer, address _racerToken, uint256 _startingRacer) ERC721("Crypto Racers", "CR")  {
        racer = _racer;
        racerToken = _racerToken;
        startingRacer = _startingRacer;  

        isCaller[_racer] = true;
        isCaller[msg.sender] = true;
        isCaller[_racerToken] = true;
        isCaller[address(this)] = true;  
       
        _tokenIds.increment(); 
    }   

    modifier onlyCaller (address _caller) {
        require (isCaller[_caller] == true, "You are not a caller");
        _;
    }

    //State: -----------------------------------------

    address public racer;
    address public racerToken; 
    uint256 public startingRacer; 
      
    mapping (address => bool) public isCaller;

    //Minting Functions: ------------------------------------------------------------------------------------

    //PAID
    function mintCar (address _minter, uint256[] calldata _nums, uint8 _paymentMethod, string memory _uri, bool _claimedFree)
    external onlyCaller (msg.sender) {

        require (_paymentMethod == 0 || _paymentMethod == 1, "Insufficient payment method");

        uint256 carID = _nums[0]; 
        uint256 price = _nums[1];
        uint256 amount = _nums[2];

        if (_claimedFree == false) {
             
            //Transfer new user racer token 
            (bool claimedFree, ) = racerToken.call(
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    _minter, startingRacer
                )
            );
            require (claimedFree, "Call failed");

        } else if (_paymentMethod == 0) {

            (bool tokenTransfer, ) = racerToken.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _minter, racerToken, price * amount  
                )
            );
            require (tokenTransfer, "Insufficient Racer");
        }

        //Minting: --------------------------------------

        uint256 _newTokenId = _tokenIds.current();
        uint256[] memory _tokenIDs = new uint256[](amount); 

        for (uint i = 0; i < amount; i++) {

            //Library functions: 
            _tokenIds.increment(); 
            _safeMint (_minter, _newTokenId);
            _setTokenURI (_newTokenId, _uri);

            _tokenIDs[i] = _newTokenId; 
        }

        require (_tokenIDs.length == amount, "Iteration error"); 
        
        _setApprovalForAll(_minter, address(this), true);
        _setApprovalForAll(_minter, racer, true);

        (bool createToken, ) = racer.call(
            abi.encodeWithSignature(
                "createToken(address,uint256,uint256[],string)",
                _minter, carID, _tokenIDs, _uri
            )
        );
        require (createToken, "Create token failed");

    }

    //Marketplace functions: ----------------------------------------------------


    function purchaseToken (address _seller, address _buyer, uint256 _tokenID, uint256 _price, uint8 _paymentMethod) external onlyCaller (msg.sender) {

        if (_paymentMethod == 0) {

            (bool tokenTransfer, ) = racerToken.call(
                abi.encodeWithSignature(
                    "transferFrom(address,address,uint256)",
                    _buyer, _seller, _price 
                )
            );
            require (tokenTransfer, "Insufficient Racer");
        }

        safeTransferFrom(_seller, _buyer, _tokenID); 
    }

    //Upgrade Functions: ---------------------------------------------------------

    function updateTokenStats (address _updater, uint256 _tokenID, uint256[] calldata _oldStats, uint256[] calldata _newStats) external onlyCaller (msg.sender) {

        uint256 cost;  
        uint256[] memory newStats = new uint256[](5);

        //Calculate Cost 
        for (uint i = 0; i < _newStats.length; i++) {

            if (_newStats[i] != _oldStats[i] && _newStats[i] != 0) {

                require (_newStats[i] <= 100 && _newStats[i] > 0, "Incompatible value");
                uint256 difference;

                if (_newStats[i] > _oldStats[i]) {
                    difference = _newStats[i] - _oldStats[i];
                    cost += difference ** 2; //Square for upgrade

                } else if (_newStats[i] < _oldStats[i]) {
                    difference = _oldStats[i] - _newStats[i];
                    cost += difference * 2; //Multiply for downgrade
                }
                newStats[i] = _newStats[i]; 

            } else if (_newStats[i] == _oldStats[i] || _newStats[i] == 0){
                newStats[i] = _oldStats[i]; 
            }
        }

        //Transfer Racer
        (bool transferRacer, ) = racerToken.call (
            abi.encodeWithSignature (
                "transferFrom(address,address,uint256)",
                _updater, racerToken, cost
            )
        );
        require (transferRacer, "Racer transfer failed");


        //Fulfill Request
        (bool fulfillStats, ) = racer.call (
            abi.encodeWithSignature (
                "updateTokenFul(uint256,uint256,uint256[])",
                _tokenID, cost, newStats
            )
        );
        require (fulfillStats, "Racer transfer failed");
    }

    //Getter Functions: ---------------------------------------------------------

    function walletOfOwner (address _owner) public view returns (uint256[] memory) {
        
        uint256 counter; 
        uint256[] memory ownerWallet = new uint256[](balanceOf(_owner)); 

        for (uint i = 1; i < _tokenIds.current(); i++) {

            if (ownerOf(i) == _owner) {
                ownerWallet[counter] = i; 
                counter += 1; 
            }
        }
        return ownerWallet; 
    }

    //Setter Functions: ----------------------------------------------------------

    function setStartingRacer (uint256 _newAmount) external onlyCaller (msg.sender) {
        startingRacer = _newAmount; 
    }

    function setCallers (address _newCaller) public onlyCaller (msg.sender) {
        isCaller[_newCaller] = true; 
    }

    function setContracts (address _racer, address _racerToken) external onlyCaller (msg.sender) {
        racer = _racer;
        racerToken = _racerToken;

        setCallers(_racer);
        setCallers(_racerToken);  
    }
}