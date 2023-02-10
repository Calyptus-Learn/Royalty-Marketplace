// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IRentableNFT is IERC721 {
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);
}
