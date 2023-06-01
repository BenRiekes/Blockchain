//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./SchedulerBase.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol";

contract Scheduler is SchedulerBase {

    //Access Control: -----------------------------------------------
   
    modifier Auth (bytes32 _jobID, bool _onlyOwner) {

        require (IDToJob[_jobID].ID == _jobID && IDToJob[_jobID].isActive,
            "Invalid ID or query for inactive Job"
        );

        if (_onlyOwner) {
            require (IDToJob[_jobID].owner == msg.sender);
        }
        _;
    }

    //Info Getters: ------------------------------------------------

    function getFulfillment (bytes32 _jobID, uint256 _index) external view returns (bool[] memory success, bytes[] memory responses, uint256 timestamp) {

        require (IDToJob[_jobID].fulfillments.length > _index, 
            "Index out of bounds"
        ); 

        Fulfillment memory fulfillment = IDToJob[_jobID].fulfillments[_index];

        return (fulfillment.success, fulfillment.response, fulfillment.timestamp);
    }

    function getCall (bytes32 _jobID, uint256 _index) external view returns (bytes memory data, address target, uint256 funding) {

        require (IDToJob[_jobID].calls.length > _index, 
            "Index out of bounds"
        );

        Call memory call = IDToJob[_jobID].calls[_index];

        return (call.data, call.target, call.funding);
    }

    function getJobFunding (bytes32 _jobID) public view returns (uint256 funding) {

        for (uint i = 0; i < IDToJob[_jobID].calls.length; i++) {
            funding += IDToJob[_jobID].calls[i].funding;
        }
    }

    //Helper Functions: -------------------------------------------------

    function buildSchedule (uint256[] memory _dates) internal pure returns (string memory) {

        string memory schedule = "";

        for (uint i = 0; i < _dates.length; i++) {

            schedule = string(abi.encodePacked(
               schedule, 
               i == 0 ? "" : ", ", 
               Strings.toString(_dates[i])
            ));
        }

        return schedule;
    }

    function verifyBounds (uint256[] memory _dates, uint256[] memory _lower, uint256[] memory _upper) internal pure returns (bool) {

        require (_dates.length == _lower.length && _lower.length == _upper.length,
            "Invalid parameters"
        ); 

        for (uint i = 0; i < _dates.length; i++) {

            if (_dates[i] < _lower[i] || _dates[i] > _upper[i]) {
                return false;
            }
        }

        return true;
    }   

    function verifySchedule (bytes memory _schedule, JobTypes _type) internal view returns (bool verified, string memory schedule) {

        if (_type == JobTypes.Cron) {
            verified = _schedule.length >= 5; 
            schedule = string(_schedule);
        }

        else if (_type == JobTypes.Date) {
            uint256[] memory arr = abi.decode(_schedule, (uint256[]));
            verified = verifyBounds(arr, DateLB, DateUB);
            schedule = buildSchedule(arr);
        }

        else if (_type == JobTypes.Recurrence) {
            uint256[] memory arr = abi.decode(_schedule, (uint256[]));
            verified = verifyBounds (arr, ReccurenceLB, ReccurenceUB);
            schedule = buildSchedule(arr);
        }

        else if (_type == JobTypes.Blocktime) {
            uint256 blocktime = abi.decode(_schedule, (uint256)); 
            verified = blocktime > block.timestamp;
            schedule = Strings.toString(blocktime);
        }
    } 

    //Primary Functions: ------------------------------------------------

    function createJob (Call[] memory _calls, bytes memory _schedule, JobTypes _type, address _validator) external returns (bytes32 ID) {

        (bool verified, string memory schedule) = verifySchedule(
            _schedule, _type
        ); 

        require (verified, "Incorrect schedule or job type"); 
        require (_validator != address(this), "Invalid validator"); 
    
        ID = keccak256(abi.encodePacked(
            block.timestamp, block.number, block.prevrandao, msg.sender
        ));

        IDToJob[ID].ID = ID;
        IDToJob[ID].isActive = true;
        IDToJob[ID].owner = msg.sender;
        IDToJob[ID].validator = _validator;

        IDToJob[ID].jobType = _type;
        IDToJob[ID].schedule = schedule;
        
        for (uint i = 0; i < _calls.length; i++) {
            addCall(ID, _calls[i]);
        }
    }

    function fulfillJob (bytes32 _jobID) external Auth (_jobID, false) {

        Job memory job = IDToJob[_jobID];

        require (job.validator == msg.sender, 
            "Unauthorized validator"    
        ); 

        require (address(this).balance >= getJobFunding(_jobID) && Subscription[job.owner] >= getJobFunding(_jobID),
            "Insufficient contract or subscription balance"
        ); 

        bool[] memory successes = new bool[](job.calls.length);
        bytes[] memory responses = new bytes[](job.calls.length);

        for (uint i = 0; i < job.calls.length; i++) {

            (bool success, bytes memory response) = payable(job.calls[i].target).call{
                value: job.calls[i].funding

            }(job.calls[i].data);

            if (success) {
                Subscription[job.owner] -= job.calls[i].funding;
            }

            successes[i] = success;
            responses[i] = response;
        }

        IDToJob[_jobID].fulfillments.push(Fulfillment({
            success: successes,
            response: responses,
            timestamp: block.timestamp
        })); 
    } 

    //Secondary Functions ------------------------------------------------

    function addCall (bytes32 _jobID, Call memory call) public Auth (_jobID, true) {

        require (call.target != address(this), 
            "Invalid target"
        ); 

        IDToJob[_jobID].calls.push(call);
    }

    function removeCall (bytes32 _jobID, uint256 _index) external Auth (_jobID, true) {

        require (IDToJob[_jobID].calls.length > _index, 
            "Index out of bounds"
        ); 

        IDToJob[_jobID].calls[_index] = IDToJob[_jobID].calls
            [IDToJob[_jobID].calls.length - 1]
        ; 

        IDToJob[_jobID].calls.pop();
    }

    //Setters: ------------------------------------------------------------

    function deleteJob (bytes32 _jobID) external Auth (_jobID, true) {
        IDToJob[_jobID].isActive = false; 
    }

    function setValidator (bytes32 _jobID, address _validator) external Auth (_jobID, true) {
        IDToJob[_jobID].validator = _validator; 
    }

    //Financial: ------------------------------------------------------------

    function deposit (address _reciever) external payable {
        Subscription[_reciever] += msg.value;
    }

    function withdraw (uint256 _amount) external {

        require (Subscription[msg.sender] >= _amount && address(this).balance > _amount, 
            "Insufficient balance"
        );

        Subscription[msg.sender] -= _amount;

        (bool success, ) = payable(msg.sender).call{
            value: _amount

        }(""); require (success, "Transfer failed"); 
    }
}
