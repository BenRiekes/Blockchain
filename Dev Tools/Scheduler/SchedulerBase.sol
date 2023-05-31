//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract SchedulerBase {

    event JobCreated (bytes32 ID, address Owner, 
        address Validator, uint256 Timestamp
    );

    event JobFulfilled (bytes32 ID, address Validator, 
        bool[] Success, bytes[] Data, uint256 Timestamp
    );

    //------------------------------------------------

    enum JobTypes {Undeclared, Cron, Date, Recurrence, Blocktime}

    struct Call {
        bytes data;
        address target;
        uint256 funding;
    }

    struct Fulfillment {
        bool[] success;
        bytes[] response;
        uint256 timestamp;
    }

    struct Job {
        bytes32 ID;
        address owner;
        address validator;

        string schedule;
        bool isActive;
        JobTypes jobType;

        Call[] calls;
        Fulfillment[] fulfillments;
    }

    bytes32[] public JobIDs;

    mapping (bytes32 => Job) public IDToJob;
    mapping (address => uint256) public Subscription;

   
}