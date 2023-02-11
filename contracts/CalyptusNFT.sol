// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";

/* Calyptus NFT-ERC721 */
contract CalyptusNFT is
    ERC721URIStorage,
    ERC721Burnable,
    ERC721Royalty,
    Ownable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    /**
     * @param _name Name of the NFT
     * @param _symbol Symbol of the NFT
     * @param _owner Address of the Creator
     * @param royaltyFee Royalty fee (*10^2) eg. for 1%, put 100
     * @param royaltyRecipient Address of the receiver of the royalty
     */
    constructor(
        string memory _name,
        string memory _symbol,
        address _owner,
        uint96 royaltyFee,
        address royaltyRecipient
    ) ERC721(_name, _symbol) {
        _setDefaultRoyalty(royaltyRecipient, royaltyFee);
        transferOwnership(_owner);
    }

    /**
     * @notice Mint a new NFT
     * @param to Address of the receiver of the NFT
     * @param uri URI to be attached to the NFT
     */
    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    function _burn(
        uint256 tokenId
    ) internal override(ERC721Royalty, ERC721URIStorage, ERC721) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Royalty, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
