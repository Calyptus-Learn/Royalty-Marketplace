// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "contracts/Interfaces/IMarketplace.sol";
import "contracts/Interfaces/ICalyptusNFTFactory.sol";
import "contracts/Interfaces/ICalyptusNFT.sol";

contract CalyptusNFTMarketplace is Ownable, ReentrancyGuard, IMarketplace {
    ICalyptusNFTFactory private immutable calyptusNFTFactory;

    uint256 private platformFee;
    address private feeRecipient;

    mapping(address => bool) private payableToken;
    address[] private tokens;

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListedNFT)) private listedNfts;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferDetails)))
        private offers;

    // nft => tokenId => auction struct
    mapping(address => mapping(uint256 => AuctionNFT)) private auctionNfts;

    // auction index => bidding counts => bidder address => bid price
    mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
        private bidPrices;

    constructor(
        uint256 _platformFee,
        address _feeRecipient,
        ICalyptusNFTFactory _calyptusNFTFactory
    ) {
        require(_platformFee <= 10000, "can't be more than 10 percent");
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
        calyptusNFTFactory = _calyptusNFTFactory;
    }

    modifier isListedNFT(address _nft, uint256 _tokenId) {
        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];
        require(
            listedNFT.seller != address(0) && !listedNFT.sold,
            "not listed"
        );
        _;
    }

    modifier isNotListedNFT(address _nft, uint256 _tokenId) {
        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];
        require(
            listedNFT.seller == address(0) || listedNFT.sold,
            "already listed"
        );
        _;
    }

    modifier isAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft != address(0) && !auction.success,
            "auction already created"
        );
        _;
    }

    modifier isNotAuction(address _nft, uint256 _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(
            auction.nft == address(0) || auction.success,
            "auction already created"
        );
        _;
    }

    modifier isOfferedNFT(
        address _nft,
        uint256 _tokenId,
        address _offerer
    ) {
        OfferDetails memory offer = offers[_nft][_tokenId][_offerer];
        require(
            offer.offerPrice > 0 && offer.offerer != address(0),
            "not offered nft"
        );
        _;
    }

    modifier isPayableToken(address _payToken) {
        require(
            _payToken != address(0) && payableToken[_payToken],
            "invalid pay token"
        );
        _;
    }

    /**
     * @notice put the NFT on marketplace
     * @param _nft specified NFT collection address
     * @param _tokenId specified NFT id to sell
     * @param _payToken ERC-20 token address for trading
     * @param _price the price of NFT
     */
    function createSale(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isPayableToken(_payToken) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        nft.transferFrom(msg.sender, address(this), _tokenId);

        listedNfts[_nft][_tokenId] = ListedNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: _payToken,
            price: _price,
            sold: false
        });

        emit NFTListed(_nft, _tokenId, _payToken, _price, msg.sender);
    }

    /**
     * @notice cancel listed NFT from marketplace
     * @param _nft NFT collection address to sell
     * @param _tokenId specified NFT id to sell
     */
    function cancelListedNFT(
        address _nft,
        uint256 _tokenId
    ) external isListedNFT(_nft, _tokenId) {
        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];
        require(listedNFT.seller == msg.sender, "Only Lister");
        IERC721(_nft).transferFrom(address(this), msg.sender, _tokenId);
        delete listedNfts[_nft][_tokenId];
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nft NFT collection address to buy
     * @param _tokenId specified NFT id to buy
     * @param _payToken ERC-20 token address for trading
     * @param _price NFT price
     */
    function buy(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isListedNFT(_nft, _tokenId) {
        ListedNFT storage listedNft = listedNfts[_nft][_tokenId];
        require(_payToken == listedNft.payToken, "invalid pay token");
        require(!listedNft.sold, "nft already sold");
        require(_price >= listedNft.price, "invalid price");

        listedNft.sold = true;

        uint256 payablePrice = _price;
        ICalyptusNFT nft = ICalyptusNFT(listedNft.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, _price);
            payablePrice -= royaltyTotal;

            // Transfer royalty fee to the collection owner
            IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                royaltyRecipient,
                royaltyTotal
            );
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(_price);
        payablePrice -= platformFeeTotal;
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            feeRecipient,
            platformFeeTotal
        );

        // Transfer payablePrice to the nft owner
        IERC20(listedNft.payToken).transferFrom(
            msg.sender,
            listedNft.seller,
            payablePrice
        );

        // Transfer NFT to buyer
        IERC721(listedNft.nft).safeTransferFrom(
            address(this),
            msg.sender,
            listedNft.tokenId
        );

        emit BoughtNFT(
            listedNft.nft,
            listedNft.tokenId,
            listedNft.payToken,
            _price,
            listedNft.seller,
            msg.sender
        );
    }

    /**
     *
     * @param _nft address of NFT
     * @param _tokenId TokenId
     * @param _payToken ERC20 token to make payment in
     * @param _offerPrice Price offered
     */
    function makeOffer(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _offerPrice
    ) external isListedNFT(_nft, _tokenId) isPayableToken(_payToken) {
        require(_offerPrice > 0, "price can not 0");

        IERC20(_payToken).transferFrom(msg.sender, address(this), _offerPrice);

        offers[_nft][_tokenId][msg.sender] = OfferDetails({
            nft: _nft,
            tokenId: _tokenId,
            offerer: msg.sender,
            payToken: _payToken,
            offerPrice: _offerPrice
        });

        emit OfferedNFT(_nft, _tokenId, _payToken, _offerPrice, msg.sender);
    }

    /**
     * @notice cancel the made offer
     * @param _nft NFT collection address to buy
     * @param _tokenId NFT id to buy
     */
    function cancelOffer(
        address _nft,
        uint256 _tokenId
    ) external isOfferedNFT(_nft, _tokenId, msg.sender) {
        OfferDetails memory offer = offers[_nft][_tokenId][msg.sender];
        require(offer.offerer == msg.sender, "not offerer");

        bool isSold = listedNfts[_nft][_tokenId].sold;
        require(!isSold, "already sold");

        delete offers[_nft][_tokenId][msg.sender];
        IERC20(offer.payToken).transfer(offer.offerer, offer.offerPrice);
        emit CanceledOfferedNFT(_nft, _tokenId, msg.sender);
    }

    /**
     * @notice listed NFT owner accept offering
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _offerer the user address that created this offer
     */
    function acceptOffer(
        address _nft,
        uint256 _tokenId,
        address _offerer
    )
        external
        isListedNFT(_nft, _tokenId)
        isOfferedNFT(_nft, _tokenId, _offerer)
    {
        require(
            listedNfts[_nft][_tokenId].seller == msg.sender,
            "not listed owner"
        );

        ListedNFT storage list = listedNfts[_nft][_tokenId];
        require(!list.sold, "already sold");

        OfferDetails storage offer = offers[_nft][_tokenId][_offerer];

        list.sold = true;

        uint256 offerPrice = offer.offerPrice;
        uint256 totalPrice = offerPrice;

        ICalyptusNFT nft = ICalyptusNFT(offer.nft);
        address royaltyRecipient = nft.getRoyaltyRecipient();
        uint256 royaltyFee = nft.getRoyaltyFee();

        IERC20 payToken = IERC20(offer.payToken);

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, offerPrice);
            totalPrice -= royaltyTotal;

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        totalPrice -= platformFeeTotal;
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to seller
        payToken.transfer(list.seller, totalPrice);

        // Transfer NFT to offerer
        IERC721(list.nft).safeTransferFrom(
            address(this),
            offer.offerer,
            list.tokenId
        );

        emit AcceptedNFT(
            offer.nft,
            offer.tokenId,
            offer.payToken,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    /**
     * @notice create a auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _payToken ERC-20 token address for trading
     * @param _price NFT price
     * @param _minBid minimum bid price
     * @param _startTime the time to start bid.
     * @param _endTime the time to end bid and NFT is transferred to max bider.
     */
    function createAuction(
        address _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price,
        uint256 _minBid,
        uint256 _startTime,
        uint256 _endTime
    ) external isPayableToken(_payToken) isNotAuction(_nft, _tokenId) {
        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        require(_endTime > _startTime, "invalid end time");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        auctionNfts[_nft][_tokenId] = AuctionNFT({
            nft: _nft,
            tokenId: _tokenId,
            creator: msg.sender,
            payToken: _payToken,
            initialPrice: _price,
            minBid: _minBid,
            startTime: _startTime,
            endTime: _endTime,
            lastBidder: address(0),
            highestBid: _price,
            winner: address(0),
            success: false
        });

        emit CreatedAuction(
            _nft,
            _tokenId,
            _payToken,
            _price,
            _minBid,
            _startTime,
            _endTime,
            msg.sender
        );
    }

    /**
     * @notice cancel the auction to buy
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function cancelAuction(
        address _nft,
        uint256 _tokenId
    ) external isAuction(_nft, _tokenId) {
        AuctionNFT memory auction = auctionNfts[_nft][_tokenId];
        require(auction.creator == msg.sender, "not auction creator");
        require(block.timestamp < auction.startTime, "auction already started");
        require(auction.lastBidder == address(0), "already have bidder");

        IERC721 nft = IERC721(_nft);
        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete auctionNfts[_nft][_tokenId];
    }

    /**
     * @notice Bid place auction
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     * @param _bidPrice bid price
     */
    function placeBid(
        address _nft,
        uint256 _tokenId,
        uint256 _bidPrice
    ) external isAuction(_nft, _tokenId) {
        require(
            block.timestamp >= auctionNfts[_nft][_tokenId].startTime,
            "auction not start"
        );
        require(
            block.timestamp <= auctionNfts[_nft][_tokenId].endTime,
            "auction ended"
        );
        require(
            _bidPrice >=
                auctionNfts[_nft][_tokenId].highestBid +
                    auctionNfts[_nft][_tokenId].minBid,
            "less than min bid price"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        payToken.transferFrom(msg.sender, address(this), _bidPrice);

        if (auction.lastBidder != address(0)) {
            address lastBidder = auction.lastBidder;
            uint256 lastBidPrice = auction.highestBid;

            // Transfer back to last bidder
            payToken.transfer(lastBidder, lastBidPrice);
        }

        // Set new highest bid price
        auction.lastBidder = msg.sender;
        auction.highestBid = _bidPrice;

        emit PlacedBid(_nft, _tokenId, auction.payToken, _bidPrice, msg.sender);
    }

    /**
     * @notice complete auction, can call by auction creator, highest bidder, or marketplace owner only!
     * @param _nft NFT collection address
     * @param _tokenId NFT id
     */
    function completeBid(address _nft, uint256 _tokenId) external {
        require(!auctionNfts[_nft][_tokenId].success, "already resulted");
        require(
            msg.sender == owner() ||
                msg.sender == auctionNfts[_nft][_tokenId].creator ||
                msg.sender == auctionNfts[_nft][_tokenId].lastBidder,
            "not creator, winner, or owner"
        );
        require(
            block.timestamp > auctionNfts[_nft][_tokenId].endTime,
            "auction not ended"
        );

        AuctionNFT storage auction = auctionNfts[_nft][_tokenId];
        IERC20 payToken = IERC20(auction.payToken);
        IERC721 nft = IERC721(auction.nft);

        auction.success = true;
        auction.winner = auction.creator;

        ICalyptusNFT CalyptusNft = ICalyptusNFT(_nft);
        address royaltyRecipient = CalyptusNft.getRoyaltyRecipient();
        uint256 royaltyFee = CalyptusNft.getRoyaltyFee();

        uint256 highestBid = auction.highestBid;
        uint256 totalPrice = highestBid;

        if (royaltyFee > 0) {
            uint256 royaltyTotal = calculateRoyalty(royaltyFee, highestBid);

            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royaltyTotal);
            totalPrice -= royaltyTotal;
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(highestBid);
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to auction creator
        payToken.transfer(auction.creator, totalPrice - platformFeeTotal);

        // Transfer NFT to the winner
        nft.transferFrom(address(this), auction.lastBidder, auction.tokenId);

        emit ResultedAuction(
            _nft,
            _tokenId,
            auction.creator,
            auction.lastBidder,
            auction.highestBid,
            msg.sender
        );
    }

    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 10_000;
    }

    function calculateRoyalty(
        uint256 _royalty,
        uint256 _price
    ) public pure returns (uint256) {
        return (_price * _royalty) / 10_000;
    }

    function getListedNFT(
        address _nft,
        uint256 _tokenId
    ) public view returns (ListedNFT memory) {
        return listedNfts[_nft][_tokenId];
    }

    function getPayableTokens() external view returns (address[] memory) {
        return tokens;
    }

    function checkIsPayableToken(
        address _payableToken
    ) external view returns (bool) {
        return payableToken[_payableToken];
    }

    function addPayableToken(address _token) external onlyOwner {
        require(_token != address(0), "invalid token");
        require(!payableToken[_token], "already payable token");
        payableToken[_token] = true;
        tokens.push(_token);
    }

    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        require(_platformFee <= 10000, "can't more than 10 percent");
        platformFee = _platformFee;
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "can't be 0 address");
        feeRecipient = _feeRecipient;
    }
}
