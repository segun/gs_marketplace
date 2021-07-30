// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./interfaces/IERC721.sol";

contract MarketPlace {
    event Listed(address indexed erc721, uint256 indexed tokenId, uint256 startDate, uint256 endDate);

    uint256 internal listingFee = 0.01 ether;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => bytes32) roles;

    address admin;

    //erc71 => tokenId => startDate
    mapping(address => mapping(uint256 => uint256)) internal startDate;
    //erc71 => tokenId => endDate
    mapping(address => mapping(uint256 => uint256)) internal endDate;    
    //erc71 => tokenId => minBid
    mapping(address => mapping(uint256 => uint256)) internal minBid;        
    //erc71 => tokenId => currentBid
    mapping(address => mapping(uint256 => uint256)) internal currentBid;            
    //erc71 => tokenId => currentBidder
    mapping(address => mapping(uint256 => address)) internal currentBidder;
    //erc71 => tokenId => bids[]
    mapping(address => mapping(uint256 => uint256[])) internal bids;
    //erc71 => tokenId => bidders[]
    mapping(address => mapping(uint256 => uint256[])) internal bidders;    


    constructor() {
        admin = msg.sender;
    }

    modifier is_admin(address _check) {
        require(hasRole(_check, ADMIN_ROLE), 'Only Admin');
        _;
    }

    function list(
        address _erc721, 
        uint256 _tokenId, 
        uint256 _startDate, 
        uint256 _endDate,
        uint256 _minBid
    ) public payable {
        emit Listed(_erc721, _tokenId, _startDate, _endDate);
    }

    function setListingFee(uint256 _newFee) public is_admin(msg.sender) {
        listingFee = _newFee;
    }

    function hasRole(address _check, bytes32 _role) internal view returns(bool) {
        return roles[_check] == _role;
    }

    function auctionIsActive(address _erc721, uint256 _tokenId) internal view returns (bool) {
        return block.timestamp >= startDate[_erc721][_tokenId] && block.timestamp < endDate[_erc721][_tokenId];
    }
}