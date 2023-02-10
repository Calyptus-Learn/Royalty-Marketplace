Summary

- [shadowing-local](#shadowing-local) (3 results) (Low)
- [events-maths](#events-maths) (1 results) (Low)
- [variable-scope](#variable-scope) (3 results) (Low)
- [reentrancy-events](#reentrancy-events) (4 results) (Low)
- [pragma](#pragma) (1 results) (Informational)
- [solc-version](#solc-version) (23 results) (Informational)
- [low-level-calls](#low-level-calls) (4 results) (Informational)
- [naming-convention](#naming-convention) (26 results) (Informational)

## shadowing-local

Impact: Low
Confidence: High

- [ ] ID-9
      [CalyptusNFT.constructor(string,string,address,uint96,address).\_name](contracts/CalyptusNFT.sol#L22) shadows: - [ERC721.\_name](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L24) (state variable)

contracts/CalyptusNFT.sol#L22

- [ ] ID-10
      [CalyptusNFT.constructor(string,string,address,uint96,address).\_symbol](contracts/CalyptusNFT.sol#L23) shadows: - [ERC721.\_symbol](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L27) (state variable)

contracts/CalyptusNFT.sol#L23

- [ ] ID-11
      [CalyptusNFT.constructor(string,string,address,uint96,address).\_owner](contracts/CalyptusNFT.sol#L24) shadows: - [Ownable.\_owner](node_modules/@openzeppelin/contracts/access/Ownable.sol#L21) (state variable)

contracts/CalyptusNFT.sol#L24

## events-maths

Impact: Low
Confidence: Medium

- [ ] ID-12
      [CalyptusNFTMarketplace.updatePlatformFee(uint256)](contracts/Marketplace.sol#L326-L329) should emit an event for: - [platformFee = \_platformFee](contracts/Marketplace.sol#L328)

contracts/Marketplace.sol#L326-L329

## variable-scope

Impact: Low
Confidence: High

- [ ] ID-13
      Variable '[ERC721.\_checkOnERC721Received(address,address,uint256,bytes).reason](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L438)' in [ERC721.\_checkOnERC721Received(address,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L429-L451) potentially used before declaration: [revert(uint256,uint256)(32 + reason,mload(uint256)(reason))](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L444)

node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L438

- [ ] ID-14
      Variable '[ERC721.\_checkOnERC721Received(address,address,uint256,bytes).retval](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L436)' in [ERC721.\_checkOnERC721Received(address,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L429-L451) potentially used before declaration: [retval == IERC721Receiver.onERC721Received.selector](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L437)

node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L436

- [ ] ID-15
      Variable '[ERC721.\_checkOnERC721Received(address,address,uint256,bytes).reason](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L438)' in [ERC721.\_checkOnERC721Received(address,address,uint256,bytes)](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L429-L451) potentially used before declaration: [reason.length == 0](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L439)

node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L438

## reentrancy-events

Impact: Low
Confidence: Medium

- [ ] ID-16
      Reentrancy in [CalyptusNFTMarketplace.buy(address,uint256,uint256)](contracts/Marketplace.sol#L109-L175):
      External calls: - [! IERC20(listedNft.payToken).transferFrom(msg.sender,royaltyRecipient,royalty)](contracts/Marketplace.sol#L132-L136) - [! IERC20(listedNft.payToken).transferFrom(msg.sender,feeRecipient,platformFeeTotal)](contracts/Marketplace.sol#L144-L148) - [! IERC20(listedNft.payToken).transferFrom(msg.sender,listedNft.seller,payablePrice)](contracts/Marketplace.sol#L153-L157) - [IERC721(listedNft.nft).safeTransferFrom(address(this),msg.sender,listedNft.tokenId)](contracts/Marketplace.sol#L161-L165)
      Event emitted after the call(s): - [BoughtNFT(listedNft.nft,listedNft.tokenId,listedNft.payToken,\_price,listedNft.seller,msg.sender)](contracts/Marketplace.sol#L167-L174)

contracts/Marketplace.sol#L109-L175

- [ ] ID-17
      Reentrancy in [CalyptusNFTMarketplace.cancelOffer(address,uint256)](contracts/Marketplace.sol#L214-L231):
      External calls: - [! IERC20(listedNFT.payToken).transfer(offer.offerer,offer.offerPrice)](contracts/Marketplace.sol#L225-L228)
      Event emitted after the call(s): - [OfferCanceled(\_nft,\_tokenId,msg.sender)](contracts/Marketplace.sol#L230)

contracts/Marketplace.sol#L214-L231

- [ ] ID-18
      Reentrancy in [CalyptusNFTMarketplace.acceptOffer(address,uint256,address)](contracts/Marketplace.sol#L239-L294):
      External calls: - [! payToken.transfer(royaltyRecipient,royalty)](contracts/Marketplace.sol#L270) - [! payToken.transfer(feeRecipient,platformFeeTotal)](contracts/Marketplace.sol#L277) - [! payToken.transfer(list.seller,totalPrice)](contracts/Marketplace.sol#L281) - [nft.safeTransferFrom(address(this),offer.offerer,offer.tokenId)](contracts/Marketplace.sol#L285)
      Event emitted after the call(s): - [OfferAccepted(offer.nft,offer.tokenId,offer.offerPrice,offer.offerer,list.seller)](contracts/Marketplace.sol#L287-L293)

contracts/Marketplace.sol#L239-L294

- [ ] ID-19
      Reentrancy in [CalyptusNFTMarketplace.createSale(address,uint256,address,uint256)](contracts/Marketplace.sol#L61-L86):
      External calls: - [nft.safeTransferFrom(msg.sender,address(this),\_tokenId)](contracts/Marketplace.sol#L83)
      Event emitted after the call(s): - [NFTListed(\_nft,\_tokenId,\_payToken,\_price,msg.sender)](contracts/Marketplace.sol#L85)

contracts/Marketplace.sol#L61-L86

## pragma

Impact: Informational
Confidence: High

- [ ] ID-24
      Different versions of Solidity are used: - Version used: ['^0.8.0', '^0.8.1', '^0.8.14'] - [^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L4) - [^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) - [^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) - [^0.8.14](contracts/CalyptusNFT.sol#L2) - [^0.8.14](contracts/Interfaces/IRentableNFT.sol#L2) - [^0.8.14](contracts/Marketplace.sol#L2) - [^0.8.14](contracts/MarketplaceDatatypes.sol#L2)

node_modules/@openzeppelin/contracts/access/Ownable.sol#L4

## solc-version

Impact: Informational
Confidence: High

- [ ] ID-25
      Pragma version[^0.8.14](contracts/MarketplaceDatatypes.sol#L2) allows old versions

contracts/MarketplaceDatatypes.sol#L2

- [ ] ID-26
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/math/Math.sol#L4

- [ ] ID-27
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Context.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Context.sol#L4

- [ ] ID-28
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Strings.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Strings.sol#L4

- [ ] ID-29
      Pragma version[^0.8.14](contracts/Marketplace.sol#L2) allows old versions

contracts/Marketplace.sol#L2

- [ ] ID-30
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol#L4

- [ ] ID-31
      Pragma version[^0.8.1](node_modules/@openzeppelin/contracts/utils/Address.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Address.sol#L4

- [ ] ID-32
      solc-0.8.17 is not recommended for deployment

- [ ] ID-33
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol#L4

- [ ] ID-34
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L4

- [ ] ID-35
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol#L4

- [ ] ID-36
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/Counters.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/Counters.sol#L4

- [ ] ID-37
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol#L4

- [ ] ID-38
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/interfaces/IERC2981.sol#L4

- [ ] ID-39
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/ERC165.sol#L4

- [ ] ID-40
      Pragma version[^0.8.14](contracts/Interfaces/IRentableNFT.sol#L2) allows old versions

contracts/Interfaces/IRentableNFT.sol#L2

- [ ] ID-41
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/IERC721.sol#L4

- [ ] ID-42
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol#L4

- [ ] ID-43
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol#L4

- [ ] ID-44
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/access/Ownable.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/access/Ownable.sol#L4

- [ ] ID-45
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/utils/introspection/IERC165.sol#L4

- [ ] ID-46
      Pragma version[^0.8.0](node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L4) allows old versions

node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol#L4

- [ ] ID-47
      Pragma version[^0.8.14](contracts/CalyptusNFT.sol#L2) allows old versions

contracts/CalyptusNFT.sol#L2

## low-level-calls

Impact: Informational
Confidence: High

- [ ] ID-48
      Low level call in [Address.functionCallWithValue(address,bytes,uint256,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137): - [(success,returndata) = target.call{value: value}(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L135)

node_modules/@openzeppelin/contracts/utils/Address.sol#L128-L137

- [ ] ID-49
      Low level call in [Address.sendValue(address,uint256)](node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65): - [(success) = recipient.call{value: amount}()](node_modules/@openzeppelin/contracts/utils/Address.sol#L63)

node_modules/@openzeppelin/contracts/utils/Address.sol#L60-L65

- [ ] ID-50
      Low level call in [Address.functionStaticCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162): - [(success,returndata) = target.staticcall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L160)

node_modules/@openzeppelin/contracts/utils/Address.sol#L155-L162

- [ ] ID-51
      Low level call in [Address.functionDelegateCall(address,bytes,string)](node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187): - [(success,returndata) = target.delegatecall(data)](node_modules/@openzeppelin/contracts/utils/Address.sol#L185)

node_modules/@openzeppelin/contracts/utils/Address.sol#L180-L187

## naming-convention

Impact: Informational
Confidence: High

- [ ] ID-52
      Parameter [CalyptusNFTMarketplace.buy(address,uint256,uint256).\_nft](contracts/Marketplace.sol#L110) is not in mixedCase

contracts/Marketplace.sol#L110

- [ ] ID-53
      Parameter [CalyptusNFTMarketplace.createSale(address,uint256,address,uint256).\_nft](contracts/Marketplace.sol#L62) is not in mixedCase

contracts/Marketplace.sol#L62

- [ ] ID-54
      Parameter [CalyptusNFTMarketplace.calculatePlatformFee(uint256).\_price](contracts/Marketplace.sol#L297) is not in mixedCase

contracts/Marketplace.sol#L297

- [ ] ID-55
      Parameter [CalyptusNFTMarketplace.createSale(address,uint256,address,uint256).\_tokenId](contracts/Marketplace.sol#L63) is not in mixedCase

contracts/Marketplace.sol#L63

- [ ] ID-56
      Parameter [CalyptusNFTMarketplace.cancelOffer(address,uint256).\_tokenId](contracts/Marketplace.sol#L216) is not in mixedCase

contracts/Marketplace.sol#L216

- [ ] ID-57
      Parameter [CalyptusNFTMarketplace.acceptOffer(address,uint256,address).\_tokenId](contracts/Marketplace.sol#L241) is not in mixedCase

contracts/Marketplace.sol#L241

- [ ] ID-58
      Parameter [CalyptusNFTMarketplace.addPayableToken(address).\_token](contracts/Marketplace.sol#L319) is not in mixedCase

contracts/Marketplace.sol#L319

- [ ] ID-59
      Parameter [CalyptusNFTMarketplace.buy(address,uint256,uint256).\_tokenId](contracts/Marketplace.sol#L111) is not in mixedCase

contracts/Marketplace.sol#L111

- [ ] ID-60
      Parameter [CalyptusNFTMarketplace.createSale(address,uint256,address,uint256).\_payToken](contracts/Marketplace.sol#L64) is not in mixedCase

contracts/Marketplace.sol#L64

- [ ] ID-61
      Parameter [CalyptusNFTMarketplace.makeOffer(address,uint256,uint256).\_tokenId](contracts/Marketplace.sol#L185) is not in mixedCase

contracts/Marketplace.sol#L185

- [ ] ID-62
      Parameter [CalyptusNFTMarketplace.acceptOffer(address,uint256,address).\_offerer](contracts/Marketplace.sol#L242) is not in mixedCase

contracts/Marketplace.sol#L242

- [ ] ID-63
      Parameter [CalyptusNFTMarketplace.createSale(address,uint256,address,uint256).\_price](contracts/Marketplace.sol#L65) is not in mixedCase

contracts/Marketplace.sol#L65

- [ ] ID-64
      Parameter [CalyptusNFTMarketplace.makeOffer(address,uint256,uint256).\_offerPrice](contracts/Marketplace.sol#L186) is not in mixedCase

contracts/Marketplace.sol#L186

- [ ] ID-65
      Parameter [ERC2981.royaltyInfo(uint256,uint256).\_tokenId](node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L43) is not in mixedCase

node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L43

- [ ] ID-66
      Parameter [CalyptusNFTMarketplace.checkIsPayableToken(address).\_payableToken](contracts/Marketplace.sol#L314) is not in mixedCase

contracts/Marketplace.sol#L314

- [ ] ID-67
      Parameter [CalyptusNFTMarketplace.getListedNFT(address,uint256).\_nft](contracts/Marketplace.sol#L303) is not in mixedCase

contracts/Marketplace.sol#L303

- [ ] ID-68
      Parameter [CalyptusNFTMarketplace.makeOffer(address,uint256,uint256).\_nft](contracts/Marketplace.sol#L184) is not in mixedCase

contracts/Marketplace.sol#L184

- [ ] ID-69
      Parameter [CalyptusNFTMarketplace.updatePlatformFee(uint256).\_platformFee](contracts/Marketplace.sol#L326) is not in mixedCase

contracts/Marketplace.sol#L326

- [ ] ID-70
      Parameter [CalyptusNFTMarketplace.cancelListedNFT(address,uint256).\_tokenId](contracts/Marketplace.sol#L95) is not in mixedCase

contracts/Marketplace.sol#L95

- [ ] ID-71
      Parameter [CalyptusNFTMarketplace.buy(address,uint256,uint256).\_price](contracts/Marketplace.sol#L112) is not in mixedCase

contracts/Marketplace.sol#L112

- [ ] ID-72
      Parameter [ERC2981.royaltyInfo(uint256,uint256).\_salePrice](node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L43) is not in mixedCase

node_modules/@openzeppelin/contracts/token/common/ERC2981.sol#L43

- [ ] ID-73
      Parameter [CalyptusNFTMarketplace.acceptOffer(address,uint256,address).\_nft](contracts/Marketplace.sol#L240) is not in mixedCase

contracts/Marketplace.sol#L240

- [ ] ID-74
      Parameter [CalyptusNFTMarketplace.cancelListedNFT(address,uint256).\_nft](contracts/Marketplace.sol#L94) is not in mixedCase

contracts/Marketplace.sol#L94

- [ ] ID-75
      Parameter [CalyptusNFTMarketplace.getListedNFT(address,uint256).\_tokenId](contracts/Marketplace.sol#L304) is not in mixedCase

contracts/Marketplace.sol#L304

- [ ] ID-76
      Parameter [CalyptusNFTMarketplace.cancelOffer(address,uint256).\_nft](contracts/Marketplace.sol#L215) is not in mixedCase

contracts/Marketplace.sol#L215

- [ ] ID-77
      Parameter [CalyptusNFTMarketplace.changeFeeRecipient(address).\_feeRecipient](contracts/Marketplace.sol#L331) is not in mixedCase

contracts/Marketplace.sol#L331
