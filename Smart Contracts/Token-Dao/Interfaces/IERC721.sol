//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.19;

interface IERC721 {
    function owner() external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
    function walletOfOwner(address _owner) external view returns (uint256[] memory);  
    function totalSupply() external view returns (uint256); 
}