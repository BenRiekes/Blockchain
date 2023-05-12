//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface ICustomVRF {

    //Getters:
    function getLatestRequest () external view returns (uint256);
    function getRequest (uint256 _requestId) external view returns (bool, uint256[] memory);
    function getSenderRequestIDs (address _sender) external view returns (uint256[] memory);

    //Setters:
    function requestRandomWords (
        address _reciever, bool _needsRange, uint256[] memory _ranges, uint32 _numWords
    ) external returns (uint256 requestId);

}