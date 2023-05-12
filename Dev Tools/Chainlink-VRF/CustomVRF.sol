//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";


contract CustomVRF is VRFConsumerBaseV2, ConfirmedOwner {

    event Deposit (address sender,
        uint256 value, uint256 timestamp
    );

    event RequestSent (uint256 requestId, address sender, 
        address reciever, uint256 numWords, uint256 timestamp 
    );

    event RequestFullfilled (uint256 requestId, uint256[] randomWords,
        address reciever, uint256 timestamp
    ); 

    //------------------------------------------------------------------

    VRFCoordinatorV2Interface COORDINATOR;

    struct Request {
        uint256 ID;
        address reciever; 

        uint256[] ranges;
        uint256[] randomWords;

        bool needsRange; 
        bool fulfilled;
    }   

    uint64 public SubscriptionID; 
    uint16 public requestConfirmations;
    uint32 public callbackGasLimit;

    uint256[] public RequestIDs;
    mapping (uint256 => Request) public IDToRequest;

    mapping (address => bool) public AccessControl;
    mapping (address => uint256[]) public SenderToRequestIDs;

    constructor (uint64 _subscriptionID) VRFConsumerBaseV2(
        0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625

    ) ConfirmedOwner(msg.sender) {

        COORDINATOR = VRFCoordinatorV2Interface(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625
        );

        requestConfirmations = 3;
        callbackGasLimit = 300000;
        SubscriptionID = _subscriptionID;
    }

    //------------------------------------------------------------------

    function getRequest (uint256 _requestId) external view returns (bool, uint256[] memory) {
        return (IDToRequest[_requestId].fulfilled, IDToRequest[_requestId].randomWords); 
    }

    function getLatestRequest () external view returns (uint256) {
        return RequestIDs[RequestIDs.length - 1];
    }

    function getSenderRequestIDs (address _sender) external view returns (uint256[] memory) {
        return SenderToRequestIDs[_sender]; 
    }

    //------------------------------------------------------------------

    function requestRandomWords (address _reciever, bool _needsRange, uint256[] memory _ranges, uint32 _numWords) external returns (uint256 requestId) {

        require (AccessControl[msg.sender], "Unauthorized"); 

        if (_needsRange) {

            require (_ranges.length == 2 && _ranges[0] > _ranges[1],
                "Insufficient range, top range must be > bottomRange"
            );
        }

        requestId = COORDINATOR.requestRandomWords(
            0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            SubscriptionID, requestConfirmations, callbackGasLimit, _numWords
        );

        IDToRequest[requestId] = Request({
            ID: requestId,
            reciever: _reciever,

            ranges: _ranges,
            randomWords: new uint256[] (0),

            needsRange: _needsRange, 
            fulfilled: false
        }); 

        RequestIDs.push(requestId);
        SenderToRequestIDs[msg.sender].push(requestId);  

        emit RequestSent (requestId, msg.sender, _reciever, _numWords, block.timestamp);
    }

    //------------------------------------------------------------------

    function fulfillRandomWords (uint256 _requestId, uint256[] memory _randomWords) internal override {
        
        require (IDToRequest[_requestId].ID == _requestId,
            "VRF request not found"
        ); 

        if (IDToRequest[_requestId].needsRange) {

            for (uint i = 0; i < _randomWords.length; i++) {

                _randomWords[i] = (
                    (_randomWords[i] % IDToRequest[_requestId].ranges[0]) 
                    + IDToRequest[_requestId].ranges[1]
                ); 
            }
        }

        (bool success, ) = address(IDToRequest[_requestId].reciever).call(

            abi.encodeWithSignature("recieveRandomWords(uint256,uint256[])",
                _requestId, _randomWords
            )

        ); require (success, "Reciever call failed"); 

        IDToRequest[_requestId].fulfilled = true;
        IDToRequest[_requestId].randomWords = _randomWords; 

        emit RequestFullfilled (_requestId, _randomWords, 
            IDToRequest[_requestId].reciever, block.timestamp
        );
    }

   //------------------------------------------------------------------

    function setAccessControl (address[] calldata _addrs, bool _option) external onlyOwner {

        for (uint i = 0; i < _addrs.length; i++) {
            AccessControl[_addrs[i]] = _option;
        }
    }

    function setSubscriptionID (uint64 _newSubscription) external onlyOwner {
        SubscriptionID = _newSubscription; 
    } 

    function setRequestConfirmations(uint16 _newConfirmations) external onlyOwner {
        requestConfirmations = _newConfirmations; 
    }

    function setCallbackGasLimit (uint32 _newLimit) external onlyOwner {
        callbackGasLimit = _newLimit; 
    }

    //------------------------------------------------------------------

    function withrawEth (uint256 _amount) external onlyOwner {

        require (address(this).balance > _amount, 
            "Insufficient balance"
        ); 

        (bool success, ) = payable(address(msg.sender)).call{
            value: _amount

        }(""); require (success, "Transfer failure");
    }

    receive () external payable {

        emit Deposit (msg.sender, msg.value, block.timestamp); 
    }
}