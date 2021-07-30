// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.3;

import "./interfaces/IERC721.sol";

contract ERC721 is IERC721 {
    mapping(address => uint256) private balances;    
    mapping(uint256 => address) private owners;
    mapping(uint256 => address) private approvals;
    mapping(address => mapping(address => bool)) private proxyApprovals;

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
        balances[from] -= 1;
        balances[to] += 1;
        owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }

    function canSpend(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || approvals[tokenId] == spender || proxyApprovals[owner][spender]);
    }
}