//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVRF {

    //Getters:
    function getRequest (bytes32 _requestID) external view returns (bool isFulfilled, uint256[] memory result);
    function getSenderRequest (address _sender, uint256 _index) external view returns (bool isFulfilled, uint256[] memory result);

    function getLatestRequest () external view returns (bool isFulfilled, uint256[] memory result);
    function getLatestSenderRequest (address _sender) external view returns (bool isFulfilled, uint256[] memory result);

    //Setters: 
    function requestVRF (address _reciever, uint256 _amount, uint256 _lowerBound, uint256 _upperBound, bool _needsRange) external returns (bytes32 ID);
}