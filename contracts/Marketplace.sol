// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "contracts/Interfaces/ICalyptusNFT.sol";

contract CalyptusNFTMarketplace is Ownable {
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

    uint256 private platformFee;
    address private feeRecipient;

    mapping(address => bool) private payableToken;
    address[] private tokens;

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListedNFT)) private listedNfts;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferDetails)))
        private offers;

    constructor(uint256 _platformFee, address _feeRecipient) {
        require(_platformFee <= 10000, "can't be more than 10 percent");
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
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

    modifier ifOfferExists(
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
        ICalyptusNFT _nft,
        uint256 _tokenId,
        address _payToken,
        uint256 _price
    ) external isPayableToken(_payToken) {
        require(_nft.ownerOf(_tokenId) == msg.sender, "not nft owner");
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        address nftAddress = address(_nft);

        listedNfts[nftAddress][_tokenId] = ListedNFT({
            nft: nftAddress,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: _payToken,
            price: _price,
            sold: false
        });

        emit NFTListed(nftAddress, _tokenId, _payToken, _price, msg.sender);
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
        (address royaltyRecipient, uint256 royalty) = nft.royaltyInfo(
            _tokenId,
            _price
        );

        if (royalty > 0) {
            payablePrice -= royalty;

            // Transfer royalty fee to the collection owner
            IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                royaltyRecipient,
                royalty
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
     * @param _offerPrice Price offered
     */
    function makeOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _offerPrice
    ) external isListedNFT(_nft, _tokenId) {
        require(_offerPrice > 0, "price can not 0");
        address _payToken = listedNfts[_nft][_tokenId].payToken;

        IERC20(_payToken).transferFrom(msg.sender, address(this), _offerPrice);

        offers[_nft][_tokenId][msg.sender] = OfferDetails({
            nft: _nft,
            tokenId: _tokenId,
            offerer: msg.sender,
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
    ) external ifOfferExists(_nft, _tokenId, msg.sender) {
        OfferDetails memory offer = offers[_nft][_tokenId][msg.sender];
        require(offer.offerer == msg.sender, "not offerer");

        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];
        require(!listedNFT.sold, "already sold");

        delete offers[_nft][_tokenId][msg.sender];
        IERC20(listedNFT.payToken).transfer(offer.offerer, offer.offerPrice);
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
        ifOfferExists(_nft, _tokenId, _offerer)
    {
        ListedNFT storage list = listedNfts[_nft][_tokenId];

        require(list.seller == msg.sender, "not listed owner");
        require(!list.sold, "already sold");

        uint256 offerPrice = offers[_nft][_tokenId][_offerer].offerPrice;
        address offerer = offers[_nft][_tokenId][_offerer].offerer;

        list.sold = true;

        uint256 totalPrice = offerPrice;
        ICalyptusNFT nft = ICalyptusNFT(_nft);

        (address royaltyRecipient, uint256 royalty) = nft.royaltyInfo(
            _tokenId,
            offerPrice
        );

        IERC20 payToken = IERC20(list.payToken);

        if (royalty > 0) {
            totalPrice -= royalty;
            // Transfer royalty fee to collection owner
            payToken.transfer(royaltyRecipient, royalty);
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(offerPrice);
        totalPrice -= platformFeeTotal;
        payToken.transfer(feeRecipient, platformFeeTotal);

        // Transfer to seller
        payToken.transfer(list.seller, totalPrice);

        // Transfer NFT to offerer
        nft.safeTransferFrom(address(this), offerer, _tokenId);

        emit AcceptedNFT(_nft, _tokenId, offerPrice, offerer, list.seller);
    }

    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 10_000;
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
    event OfferedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address payToken,
        uint256 offerPrice,
        address indexed offerer
    );
    event CanceledOfferedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        address indexed offerer
    );
    event AcceptedNFT(
        address indexed nft,
        uint256 indexed tokenId,
        uint256 offerPrice,
        address offerer,
        address indexed nftOwner
    );
}
