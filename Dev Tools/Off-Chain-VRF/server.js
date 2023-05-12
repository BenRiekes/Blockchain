const port = 3002;
require('dotenv').config();
const express = require('express');

const app = express();
const ethers = require('ethers'); 
const { Alchemy, Network, Wallet } = require ('alchemy-sdk');

//------------------------------------------------

const settings = {
    apiKey: process.env.ALCHEMY_API_KEY, 
    network: "sepolia", 
};

const provider = new ethers.AlchemyProvider(
    settings.network, settings.apiKey
);

const signer = new ethers.Wallet(
    process.env.WALLET_KEY, provider
);

//------------------------------------------------

const contractAddress = "0x4b63BEBA9457B4668ca2Dcf0502EA6DD4aB78762";

const abi = [
    "event SimpleVRF (bytes32 ID, address Reciever, uint256 Amount, uint256 Timestamp)",
    "event RangedVRF (bytes32 ID, address Reciever, uint256 Amount, uint256 LowerBound, uint256 UpperBound, uint256 Timestamp)",
    "function processVRF (bytes32 _requestID, uint256[] memory _result) external"
];

const contract = new ethers.Contract(
    contractAddress, abi, signer
);

//------------------------------------------------

async function processTransaction (ID, randomVals, Reciever) {

    const tx = await contract.processVRF(ID, randomVals);
    console.log(`Transaction: ${tx.hash} being sent to ${Reciever}`);

    const receipt = await tx.wait();
    console.log(`Request ${ID} for address ${Reciever}: has been fulfilled`); 

    return; 
}

contract.on ("SimpleVRF", async (ID, Reciever, Amount, Timestamp) => {

    console.log(`Recieved Simple VRF Request: ${ID} at ${Timestamp}`);
    
    let randomVals = [];
    const amount = Number(Amount);

    for (let i = 0; i < amount; i++) {
        randomVals[i] = Math.floor(Math.random() * Math.pow(2, 32)).toString();
    }

    console.log(`Ranged Values calculated: ${randomVals}`);
    await processTransaction(ID, randomVals, Reciever); 
});

contract.on("RangedVRF", async (ID, Reciever, Amount, LowerBound, UpperBound, Timestamp) => {

    console.log(`Recieved Ranged VRF Request ${ID} at ${Timestamp}`); 

    let randomVals = [];
    const amount = Number(Amount);
    const lowerBound = Number(LowerBound);
    const upperBound = Number(UpperBound);

    for (let i = 0; i < amount; i++) {

        randomVals[i] = (Math.floor
            (Math.random() * (upperBound - lowerBound + 1)) + lowerBound).toString()
        ;
    }

    console.log(`Ranged Values calculated: ${randomVals}`);
    await processTransaction(ID, randomVals, Reciever); 
})


app.get('/', (req, res) => {
    res.send('Hello world');
});

app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});