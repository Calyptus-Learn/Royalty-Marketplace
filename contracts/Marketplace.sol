// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "contracts/Interfaces/IRentableNFT.sol";
import "contracts/MarketplaceDatatypes.sol";

contract CalyptusNFTMarketplace is Ownable, MarketplaceDataTypes, ERC721Holder {
    uint256 private platformFee;
    address private feeRecipient;

    mapping(address => bool) private payableToken;
    address[] private tokens;

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => ListedNFT)) private listedNfts;

    // nft => tokenId => offerer address => offer struct
    mapping(address => mapping(uint256 => mapping(address => OfferDetails)))
        private offers;

    /**
     * @param _platformFee platform fee (*10^2) eg. for 1%, put 100
     * @param _feeRecipient address of receiver of the platform fee
     */
    constructor(uint256 _platformFee, address _feeRecipient) {
        if (_platformFee > 10_00) revert FeeMoreThan10Percent();
        if (_feeRecipient == address(0)) revert ZeroAddress();
        platformFee = _platformFee;
        feeRecipient = _feeRecipient;
    }

    modifier isListedNFT(address _nft, uint256 _tokenId) {
        address seller = listedNfts[_nft][_tokenId].seller;
        bool sold = listedNfts[_nft][_tokenId].sold;
        if (seller == address(0) || sold) revert NFTNotListed();
        _;
    }

    modifier ifOfferExists(
        address _nft,
        uint256 _tokenId,
        address _offerer
    ) {
        uint256 offerPrice = offers[_nft][_tokenId][_offerer].offerPrice;
        if (offerPrice == 0) revert OfferDoesNotExist();
        _;
    }

    modifier isPayableToken(address _payToken) {
        if (_payToken == address(0)) revert ZeroAddress();
        if (!payableToken[_payToken]) revert InvalidPayToken();
        _;
    }

    /**
     * @notice list the NFT on marketplace
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
        IRentableNFT nft = IRentableNFT(_nft);

        // lister is owner of the NFT
        if (nft.ownerOf(_tokenId) != msg.sender) revert CallerNotOwner();
        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];

        // NFT is not already listed
        if (listedNFT.seller != address(0) && !listedNFT.sold)
            revert NFTAlreadyListed();

        // update storage
        listedNfts[_nft][_tokenId] = ListedNFT({
            nft: _nft,
            tokenId: _tokenId,
            seller: msg.sender,
            payToken: _payToken,
            price: _price,
            sold: false
        });

        // transfer the NFT from the lister to the marketplace
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);

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
        if (listedNFT.seller != msg.sender) revert CallerNotLister();
        delete listedNfts[_nft][_tokenId];
        IERC721(_nft).safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /**
     * @notice buy a NFT from marketplace
     * @param _nft NFT collection address to buy
     * @param _tokenId specified NFT id to buy
     * @param _price NFT price
     */
    function buy(
        address _nft,
        uint256 _tokenId,
        uint256 _price
    ) external isListedNFT(_nft, _tokenId) {
        ListedNFT storage listedNft = listedNfts[_nft][_tokenId];

        if (listedNft.sold) revert AlreadySold();
        if (_price < listedNft.price) revert InvalidPrice();

        listedNft.sold = true;

        uint256 payablePrice = _price;
        IRentableNFT nft = IRentableNFT(listedNft.nft);
        (address royaltyRecipient, uint256 royalty) = nft.royaltyInfo(
            _tokenId,
            _price
        );

        if (royalty != 0) {
            payablePrice -= royalty;

            // Transfer royalty fee to the collection owner
            if (
                !IERC20(listedNft.payToken).transferFrom(
                    msg.sender,
                    royaltyRecipient,
                    royalty
                )
            ) revert PayTokenTransferFailed();
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(_price);
        payablePrice -= platformFeeTotal;
        if (
            !IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                feeRecipient,
                platformFeeTotal
            )
        ) revert PayTokenTransferFailed();

        // Transfer payablePrice to the nft owner
        if (
            !IERC20(listedNft.payToken).transferFrom(
                msg.sender,
                listedNft.seller,
                payablePrice
            )
        ) revert PayTokenTransferFailed();

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
     * @notice offer an alternate price to the lister for their NFT
     * @param _nft address of NFT
     * @param _tokenId TokenId
     * @param _offerPrice Price offered
     */
    function makeOffer(
        address _nft,
        uint256 _tokenId,
        uint256 _offerPrice
    ) external isListedNFT(_nft, _tokenId) {
        if (_offerPrice == 0) revert InvalidPrice();
        address _payToken = listedNfts[_nft][_tokenId].payToken;

        offers[_nft][_tokenId][msg.sender] = OfferDetails({
            nft: _nft,
            tokenId: _tokenId,
            offerer: msg.sender,
            offerPrice: _offerPrice
        });

        emit NewOffer(_nft, _tokenId, _payToken, _offerPrice, msg.sender);

        // transfer payToken from the offerer to the marketplace
        if (
            !IERC20(_payToken).transferFrom(
                msg.sender,
                address(this),
                _offerPrice
            )
        ) revert PayTokenTransferFailed();
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
        if (offer.offerer != msg.sender) revert CallerNotOfferer();

        ListedNFT memory listedNFT = listedNfts[_nft][_tokenId];
        if (listedNFT.sold) revert AlreadySold();

        delete offers[_nft][_tokenId][msg.sender];

        // return payToken to the offerer
        if (
            !IERC20(listedNFT.payToken).transfer(
                offer.offerer,
                offer.offerPrice
            )
        ) revert PayTokenTransferFailed();
        emit OfferCanceled(_nft, _tokenId, msg.sender);
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

        if (list.seller != msg.sender) revert CallerNotLister();
        if (list.sold) revert AlreadySold();

        OfferDetails memory offer = offers[_nft][_tokenId][_offerer];

        list.sold = true;

        uint256 totalPrice = offer.offerPrice;
        IRentableNFT nft = IRentableNFT(_nft);

        (address royaltyRecipient, uint256 royalty) = nft.royaltyInfo(
            list.tokenId,
            offer.offerPrice
        );

        IERC20 payToken = IERC20(list.payToken);

        if (royalty != 0) {
            totalPrice -= royalty;
            // Transfer royalty fee to collection owner
            if (!payToken.transfer(royaltyRecipient, royalty))
                revert PayTokenTransferFailed();
        }

        // Calculate & Transfer platform fee
        uint256 platformFeeTotal = calculatePlatformFee(offer.offerPrice);
        totalPrice -= platformFeeTotal;
        if (!payToken.transfer(feeRecipient, platformFeeTotal))
            revert PayTokenTransferFailed();

        // Transfer to seller
        if (!payToken.transfer(list.seller, totalPrice))
            revert PayTokenTransferFailed();

        // Transfer NFT to offerer
        nft.safeTransferFrom(address(this), offer.offerer, offer.tokenId);

        emit OfferAccepted(
            offer.nft,
            offer.tokenId,
            offer.offerPrice,
            offer.offerer,
            list.seller
        );
    }

    /**
     * @notice calculates the marketplace's cut in any sale as per price
     * @param _price price at which an NFT is to be sold
     */
    function calculatePlatformFee(
        uint256 _price
    ) public view returns (uint256) {
        return (_price * platformFee) / 10_000;
    }

    /**
     * @notice get the details of a particular listed token
     * @param _nft address of the concerned NFT
     * @param _tokenId tokenId of the concerned NFT
     */
    function getListedNFT(
        address _nft,
        uint256 _tokenId
    ) public view returns (ListedNFT memory) {
        return listedNfts[_nft][_tokenId];
    }

    /**
     * @notice get a list of all payable ERC20 tokens
     */
    function getPayableTokens() external view returns (address[] memory) {
        return tokens;
    }

    /**
     * @notice check by address if an ERC20 token is an accepted mode of payment
     * @param _payableToken address of the concerned ERC20 token
     */
    function checkIsPayableToken(
        address _payableToken
    ) external view returns (bool) {
        return payableToken[_payableToken];
    }

    /**
     * @notice Owner can add new ERC20 tokens to be accepted as mode of payment
     * @param _token address of the concerned ERC20 token to be added
     */
    function addPayableToken(address _token) external onlyOwner {
        if (_token == address(0)) revert ZeroAddress();
        if (payableToken[_token]) revert TokenAlreadyAdded();
        payableToken[_token] = true;
        tokens.push(_token);
    }

    /**
     * @notice Owner can update the platform fee, can't be more than 10%
     * @param _platformFee new platform fee (*10^2) eg. for 1%, put 100
     */
    function updatePlatformFee(uint256 _platformFee) external onlyOwner {
        if (_platformFee > 10_00) revert FeeMoreThan10Percent();
        platformFee = _platformFee;
    }

    /**
     * @notice owner can change the receiver of the platform fee
     * @param _feeRecipient new receiver of the platform fee
     */
    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        if (_feeRecipient == address(0)) revert ZeroAddress();
        feeRecipient = _feeRecipient;
    }
}
