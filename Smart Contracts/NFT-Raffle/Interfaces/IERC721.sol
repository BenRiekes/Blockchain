//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721 {

    //Getters: 
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
     
    //Reqs:
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}