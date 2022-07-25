// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./IERC721.sol";
import "./IERC20.sol";

contract MarketPlace {
  IERC20 immutable METABLOCK;

  event NewBid(address indexed bidder, address indexed nftAddress, uint256 tokenId, uint256 amount, uint256 timestamp);
  event BidAccepted(address indexed bidder, address indexed nftAddress, uint256 tokenId, uint256 amount, uint256 timestamp);

  struct Bid {
    address bidder;
    uint256 bidTime;

    uint256 amount;
  }

  // nft address => token id => Bid
  mapping(address => mapping(uint256 => Bid)) public bids;

  constructor(address _metaBlockAddress) {
    METABLOCK = IERC20(_metaBlockAddress);
  }

  function giveBid(address _nftAddress, uint256 _tokenId, uint256 _amount) external {
    Bid memory currentBid = bids[_nftAddress][_tokenId]; // save gas

    require(IERC721(_nftAddress).ownerOf(_tokenId) != msg.sender, 'cannot bid to self');
    require(currentBid.amount < _amount, "not enough amount");

    // take payment from the new user
    METABLOCK.transferFrom(msg.sender, address(this), _amount);

    // send payment back to latest bidder
    if(currentBid.bidder != address(0))
      METABLOCK.transfer(currentBid.bidder, currentBid.amount);

    // save new bid
    bids[_nftAddress][_tokenId] = Bid({
      bidder: msg.sender,
      bidTime: block.timestamp,
      amount: _amount
    });

    emit NewBid(msg.sender, _nftAddress, _tokenId, _amount, block.timestamp);
  }

  function acceptBid(address _nftAddress, uint256 _tokenId) external {
    Bid memory currentBid = bids[_nftAddress][_tokenId]; // save gas

    require(currentBid.bidTime + 120 > block.timestamp, 'cannot accept yet');

    // send nft to bidder
    IERC721(_nftAddress).transferFrom(msg.sender, currentBid.bidder, _tokenId);

    // clear bid
    delete bids[_nftAddress][_tokenId];

    // send payment to owner
    METABLOCK.transfer(msg.sender, currentBid.amount);

    emit BidAccepted(currentBid.bidder, _nftAddress, _tokenId, currentBid.amount, block.timestamp);
  }
}
