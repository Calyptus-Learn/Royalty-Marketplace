// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

// Errors
error ZeroAddress();
error PayTokenTransferFailed();
error FeeMoreThan10Percent();
error NFTNotListed();
error OfferDoesNotExist();
error InvalidPayToken();
error NFTAlreadyListed();
error CallerNotLister();
error CallerNotOwner();
error CallerNotOfferer();
error AlreadySold();
error InvalidPrice();
error TokenAlreadyAdded();

interface MarketplaceDataTypes {
    // struct
    struct ListedNFT {
        address nft;
        uint256 tokenId;
        address seller;
        address payToken;
        uint256 price;
        bool sold;
    }

    struct OfferDetails {
        address nft;
        uint256 tokenId;
        address offerer;
        uint256 offerPrice;
    }

    // events
    event NFTListed(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address indexed seller
    );
    event BoughtNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 price,
        address seller,
        address indexed buyer
    );
    event NewOffer(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event OfferCanceled(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed offerer
    );
    event OfferAccepted(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );
}
