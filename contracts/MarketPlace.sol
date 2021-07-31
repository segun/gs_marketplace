// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./interfaces/IERC721.sol";
import "./console.sol";


contract MarketPlace {
    event Listed(address indexed erc721, uint256 indexed tokenId, uint256 startDate, uint256 endDate);
    event Bid(address indexed erc721, uint256 indexed tokenId, address indexed bidder, uint256 bid);

    uint256 internal listingFee = 0.01 ether;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    mapping(address => bytes32) internal roles;

    address internal admin;

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
    mapping(address => mapping(uint256 => address[])) internal bidders;    


    constructor() {
        admin = msg.sender;
    }

    modifier is_admin(address check) {
        require(hasRole(check, ADMIN_ROLE), "Only Admin");
        _;
    }

    function list(
        address erc721, 
        uint256 tokenId, 
        uint256 _startDate, 
        uint256 _endDate,
        uint256 _minBid
    ) public payable {
        require(msg.value >= listingFee, "pay the listing fees");
        require(IERC721(erc721).ownerOf(tokenId) == msg.sender, "Not owner");
        require(!auctionIsActive(erc721, tokenId), "already started");
        require(!isListed(erc721, tokenId), "already listed");
        require(block.timestamp < _endDate, "inv. end date");
        startDate[erc721][tokenId] = _startDate;
        endDate[erc721][tokenId] = _endDate;
        minBid[erc721][tokenId] = _minBid;
        currentBid[erc721][tokenId] = _minBid;
        currentBidder[erc721][tokenId] = address(0);
        emit Listed(erc721, tokenId, _startDate, _endDate);
    }

    function bid(address erc721, uint256 tokenId) public payable {
        require(isListed(erc721, tokenId), "not listed");
        require(auctionIsActive(erc721, tokenId), "not started");        
        if(currentBidder[erc721][tokenId] == address(0)) {
            // First Bid
            require(minBid[erc721][tokenId] < msg.value, "too low");
        } else {
            require(currentBid[erc721][tokenId] < msg.value, "too low");
        }

        address oldBidder = currentBidder[erc721][tokenId];
        uint256 oldBid = currentBid[erc721][tokenId];

        currentBid[erc721][tokenId] = msg.value;
        currentBidder[erc721][tokenId] = msg.sender;

        bids[erc721][tokenId].push(msg.value);
        bidders[erc721][tokenId].push(msg.sender);

        // refund previous HB
        if(oldBidder != address(0)) {
            (bool success, ) = payable(oldBidder).call{value: oldBid}("");
            require(success, "Transfer failed.");
        }

        emit Bid(erc721, tokenId, msg.sender, msg.value);
    }

    function setListingFee(uint256 newFee) public is_admin(msg.sender) {
        listingFee = newFee;
    }

    function hasRole(address check, bytes32 role) internal view returns(bool) {
        return roles[check] == role;
    }

    function getBids(address erc721, uint256 tokenId) public view returns (address, uint256, address[] memory, uint256[] memory) {
        return (currentBidder[erc721][tokenId], currentBid[erc721][tokenId], bidders[erc721][tokenId], bids[erc721][tokenId]);
    }

    function isListed(address erc721, uint256 tokenId) public view returns (bool) {
        return startDate[erc721][tokenId] > 0;
    }

    function auctionIsActive(address erc721, uint256 tokenId) private view returns (bool) {
        return block.timestamp >= startDate[erc721][tokenId] && block.timestamp < endDate[erc721][tokenId];
    }
}