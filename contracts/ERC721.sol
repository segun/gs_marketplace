// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

import "./interfaces/IERC721.sol";
import "./console.sol";

contract ERC721 is IERC721 {
    mapping(address => uint256) private balances;    
    mapping(uint256 => address) private owners;
    mapping(uint256 => address) private approvals;
    mapping(address => mapping(address => bool)) private proxyApprovals;

    function mint(address to, uint256 tokenId) public {
        require(to != address(0), "can not mint  to 0");
        require(owners[tokenId] == address(0), "already minted");

        balances[to] += 1;
        owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function burn(uint256 tokenId) public {
        address owner = ownerOf(tokenId);        
        // Clear approvals if any        
        approve(address(0), tokenId);
        balances[owner] -= 1;
        delete owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }    

    function balanceOf(address owner) public view override returns (uint256) {
        return balances[owner];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return owners[tokenId];
    }

    function transferFrom(address from, address to,uint256 tokenId) public override {
        require(canSpend(msg.sender, tokenId), "Not owner, no approval");
        transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(canSpend(msg.sender, tokenId), "Not owner, no approval");
        require(to != owner, "same addresses");
        approvals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public override {
        proxyApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }     

    function transfer(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "Not your own");
        require(to != address(0), "call burn instead");
        // clear approvals if any
        approve(address(0), tokenId);
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        return approvals[tokenId];
    }

    function canSpend(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || approvals[tokenId] == spender || proxyApprovals[owner][spender]);
    }
}