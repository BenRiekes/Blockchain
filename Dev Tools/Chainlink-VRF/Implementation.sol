//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ICustomVRF.sol"; 

contract Implementation {

    ICustomVRF VRF;

    constructor (address _VRF) {

        VRF = ICustomVRF(_VRF);
    }

    event RequestedRange (uint256 ID, 
        uint256[] Ranges, uint256 NumWords, uint256 Timestamp
    );

    event RequestNoRange (uint256 ID,
        uint256 NumWords, uint256 Timestamp
    ); 

    event RecievedWords (uint256 ID, 
        uint256[] Result, uint256 Timestamp
    ); 

    //----------------------------------------------------------------

    function getRequest (uint256 _requestID) external view returns (bool fulfilled, uint256[] memory result) {
        return VRF.getRequest(_requestID);
    }

    function getLatestRequest () external view returns (uint256 requestID) {
        return VRF.getLatestRequest();
    }

    function getLatestSenderRequest () external view returns (uint256 requestID) {

        uint256[] memory requestIDs = VRF.getSenderRequestIDs(address(this)); 

        return (requestIDs[requestIDs.length -1]);
    }

    function getSenderRequestIDs () external view returns (uint256[] memory requestIDs) {
        return VRF.getSenderRequestIDs(address(this));
    }

    //----------------------------------------------------------------

    function requestRange (uint256[] memory _ranges, uint32 _numWords) external returns (uint256 requestID) {

        require (_ranges.length == 2 && _ranges[0] > _ranges[1],
            "Invalid ranges"
        ); 

        requestID = VRF.requestRandomWords(
            address(this), true, _ranges, _numWords
        ); 

        emit RequestedRange (requestID, _ranges, _numWords, block.timestamp); 
    }

    function requestNoRange (uint32 _numWords) external returns (uint256 requestID) {

        requestID = VRF.requestRandomWords(
            address(this), false, new uint256[](0), _numWords
        );

        emit RequestNoRange (requestID, _numWords, block.timestamp); 
    }   

    //----------------------------------------------------------------

    function recieveRandomWords (uint256 _requestID, uint256[] memory _randomWords) external {

        require (msg.sender == address(VRF), "Unauthorized"); 

        emit RecievedWords (_requestID, _randomWords, block.timestamp); 
    }
}