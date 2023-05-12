//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract VRF {

    event SimpleVRF (bytes32 ID, 
        address Reciever, uint256 Amount, uint256 Timestamp
    );

    event RangedVRF (bytes32 ID, address Reciever, 
        uint256 Amount, uint256 LowerBound, uint256 UpperBound, uint256 Timestamp
    );

    event ProcessedVRF (bytes32 ID, address Validator, 
        bool Success, bytes Response, uint256[] Result, uint256 Timestamp
    ); 

    event EditedValidators (address Sender, address[] Validators, 
        bool Added, uint256 Timestamp
    );

    //---------------------------------------------

    struct Request {
        bytes32 ID;
        address sender;
        address reciever;

        uint256 amount;
        uint256[] result;
        uint256 lowerBound;
        uint256 upperBound;

        bool needsRange;
        bool isFulfilled;
    }

    bytes32[] public RequestIDs;
    Request[] public FulfilledRequest;
    
    mapping (bytes32 => Request) public IDToRequest; 
    mapping (address => bool) public ValidatorStatus;
    mapping (address => bytes32[]) public SenderToRequestIDs;

    constructor () {
        ValidatorStatus[msg.sender] = true;
    }
    
    modifier OnlyValidator () {

        require (ValidatorStatus[msg.sender], "Unauthorized");
        _;
    }
    
    //---------------------------------------------

    function getRequest (bytes32 _requestID) external view returns (bool isFulfilled, uint256[] memory result) {

        return (IDToRequest[_requestID].isFulfilled, 
            IDToRequest[_requestID].result
        );
    }

    function getSenderRequest (address _sender, uint256 _index) external view returns (bool isFulfilled, uint256[] memory result) {
        
        return (IDToRequest[SenderToRequestIDs[_sender][_index]].isFulfilled, 
            IDToRequest[SenderToRequestIDs[_sender][_index]].result
        );
    } 

    function getLatestRequest () external view returns (bool isFulfilled, uint256[] memory result) {

        bytes32 _requestID = IDToRequest
            [RequestIDs[RequestIDs.length - 1]].ID
        ;

        return (IDToRequest[_requestID].isFulfilled, IDToRequest[_requestID].result);
    }

    function getLatestSenderRequest (address _sender) external view returns (bool isFulfilled, uint256[] memory result) {

        bytes32 _requestID = SenderToRequestIDs
            [_sender][SenderToRequestIDs[_sender].length - 1]
        ;

        return (IDToRequest[_requestID].isFulfilled, IDToRequest[_requestID].result);
    }

    //---------------------------------------------

    function generateID () internal view returns (bytes32) {

        return keccak256(abi.encodePacked(
            block.timestamp, block.prevrandao, block.gaslimit)
        );
    }

    //---------------------------------------------

    function requestVRF (address _reciever, uint256 _amount, uint256 _lowerBound, uint256 _upperBound, bool _needsRange) external returns (bytes32 ID) {

        require (_reciever != address(this), "Invalid reciever"); 

        require (_lowerBound < _upperBound || _lowerBound == 0 && _upperBound == 0,
            "Invalid ranges"
        ); 

        ID = generateID();

        IDToRequest[ID] = Request({
            ID: ID,
            sender: msg.sender,
            reciever: _reciever,
            amount: _amount,
            result: new uint256[](0),
            lowerBound: _lowerBound,
            upperBound: _upperBound,
            needsRange: _needsRange,
            isFulfilled: false
        });

        RequestIDs.push(ID);
        SenderToRequestIDs[msg.sender].push(ID); 

        if (!_needsRange) { emit SimpleVRF (ID, _reciever, _amount, block.timestamp); } else {

            emit RangedVRF (ID, _reciever, _amount, _lowerBound, _upperBound, block.timestamp);
        }
    }

    //---------------------------------------------

    function processVRF (bytes32 _requestID, uint256[] memory _result) external OnlyValidator {

        Request memory request = IDToRequest[_requestID]; 

        require (request.amount == _result.length, "Invalid results");
        require (!request.isFulfilled, "Request has already been processed"); 

        (bool success, bytes memory response) = address(request.reciever).call(

            abi.encodeWithSignature("recieveVRF(bytes32,uint256[])", 
                _requestID, _result
            )
        ); 

        request.result = _result;
        request.isFulfilled = true;
        IDToRequest[_requestID] = request;
        FulfilledRequest.push(request);

        emit ProcessedVRF (_requestID, msg.sender, success, response, _result, block.timestamp); 
    }  

    //---------------------------------------------

    function editValidators (address[] calldata _validators, bool _option) external OnlyValidator {

        for (uint i = 0; i < _validators.length; i++) {
            ValidatorStatus[_validators[i]] = _option;
        }

        emit EditedValidators (msg.sender, _validators, _option, block.timestamp);
    } 
}