// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./interfaces/IERC721.sol";
import "./console.sol";


contract MarketPlace {
    event Listed(address indexed erc721, uint256 indexed tokenId, uint256 startDate, uint256 endDate);
    event Bid(address indexed erc721, uint256 indexed tokenId, address indexed bidder, uint256 bid);
    event Claimed(address indexed erc721, uint256 indexed tokenId, address indexed bidder, uint256 bid, address formerOwner);

    struct Bids {
        uint256 startDate;
        uint256 endDate;
        uint256 minBid;
        uint256 currentBid;
        address currentBidder;
        uint256[] bids;
        address[] currentBidders;
    }

    uint256 public listingFee = 0.01 ether;

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
        roles[admin] = ADMIN_ROLE;
    }

    modifier is_admin(address check) {
        require(hasRole(check, ADMIN_ROLE), "only admin");
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
        if(isListed(erc721, tokenId) && auctionIsActive(erc721, tokenId)) {
            revert("already listed");
        }        
        require(block.timestamp < _endDate, "inv. end date");
        startDate[erc721][tokenId] = _startDate;
        endDate[erc721][tokenId] = _endDate;
        minBid[erc721][tokenId] = _minBid;
        currentBid[erc721][tokenId] = _minBid;
        currentBidder[erc721][tokenId] = address(0);
        emit Listed(erc721, tokenId, _startDate, _endDate);        
    }

    function bid(address erc721, uint256 tokenId) public payable {
        require(IERC721(erc721).ownerOf(tokenId) != msg.sender, "can't get high on your own supply");
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

    function claim(address erc721, uint256 tokenId) public {
        require(isListed(erc721, tokenId), "not listed");
        address owner = IERC721(erc721).ownerOf(tokenId);
        require(block.timestamp > endDate[erc721][tokenId], "still active");
        require(currentBidder[erc721][tokenId] == msg.sender, "you're not highest bidder");
        require(owner != msg.sender, "already claimed by you");
        // first transfer token 
        IERC721(erc721).transferFrom(owner, payable(msg.sender), tokenId);
        require(IERC721(erc721).ownerOf(tokenId) == msg.sender, "token transfer failed");
        // then transfer the ether
        (bool success, ) = payable(owner).call{value: currentBid[erc721][tokenId]}("");        
        require(success, "Transfer failed.");

        // reset everything
        startDate[erc721][tokenId] = 0;
        endDate[erc721][tokenId] = 0;
        minBid[erc721][tokenId] = 0;
        delete bidders[erc721][tokenId];
        delete bids[erc721][tokenId];
        currentBid[erc721][tokenId] = 0;
        currentBidder[erc721][tokenId] = address(0);

        emit Claimed(erc721, tokenId, msg.sender, currentBid[erc721][tokenId], owner);
    }

    /**
        Needed to run tests for claiming auction when auction has ended
     */
    function forceAuctionToEnd(address erc721, uint256 tokenId) public is_admin(msg.sender) {
        endDate[erc721][tokenId] = block.timestamp;
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

    // Nice to haves
    function addAdmin(address newAdmin) public is_admin(msg.sender) {
        roles[newAdmin] = ADMIN_ROLE;
    }   

    function isAdmin(address check) public view returns (bool) {
        return roles[check] == ADMIN_ROLE;
    }

    function setListingFee(uint256 newFee) public is_admin(msg.sender) {
        listingFee = newFee;
    }
    
    function getFullBids(address erc721, uint256 tokenId) public view returns (Bids memory) {
        return Bids(
            startDate[erc721][tokenId],
            endDate[erc721][tokenId],
            minBid[erc721][tokenId],
            currentBid[erc721][tokenId], 
            currentBidder[erc721][tokenId],             
            bids[erc721][tokenId],
            bidders[erc721][tokenId]
        );
    }    
}