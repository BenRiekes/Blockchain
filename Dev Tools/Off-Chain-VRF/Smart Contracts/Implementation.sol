//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IVRF.sol";

contract Implementation {

    IVRF VRF;

    constructor (address _VRF) {
        VRF = IVRF(_VRF);
    }

    bytes32[] public RequestIDs;
    mapping (bytes32 => uint256[]) public RequestIDToResult;

    //----------------------------------------------

    function requestSimpleVRF (uint256 _amount) external {

        bytes32 ID = VRF.requestVRF(
            address(this), _amount, 0, 0, false
        ); 

        RequestIDs.push(ID); 
    }

    function requestRangedVRF (uint256 _amount, uint256 _lowerBound, uint256 _upperBound) external {

        bytes32 ID = VRF.requestVRF (
            address(this), _amount, _lowerBound, _upperBound, true
        );

        RequestIDs.push(ID); 
    }   

    //----------------------------------------------

    function recieveVRF (bytes32 _requestID, uint256[] memory _results) external {

        require (address(VRF) == msg.sender, "Unauthorized");

        RequestIDToResult[_requestID] = _results; 
    }
}