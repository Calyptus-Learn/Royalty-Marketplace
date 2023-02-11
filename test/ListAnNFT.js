const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Test to list an nft:", function () {
  // Actors
  let payTokenDeployer, marketplaceOwner, nftCreator, nftOwner;

  // Smart contracts
  let marketplace, payToken, nft;

  before(async function () {
    [payTokenDeployer, marketplaceOwner, nftCreator, nftOwner, bob] =
      await ethers.getSigners();

    // Deploy Payment Token
    const PayToken = await ethers.getContractFactory("USD", payTokenDeployer);
    payToken = await PayToken.deploy();

    // Deploy marketplace
    const Marketplace = await ethers.getContractFactory(
      "CalyptusNFTMarketplace",
      marketplaceOwner
    );
    marketplace = await Marketplace.deploy(1000, marketplaceOwner.address);
    expect(await marketplace.calculatePlatformFee(100)).to.equal(10);

    // Add payment token as mode of payment to the NFT marketplace
    await marketplace
      .connect(marketplaceOwner)
      .addPayableToken(payToken.address);
    expect(await marketplace.checkIsPayableToken(payToken.address)).to.equal(
      true
    );

    // Deploy NFT contract and mint an NFT
    const NFT = await ethers.getContractFactory("CalyptusNFT", nftCreator);
    nft = await NFT.deploy(
      "Calyptus",
      "Cal",
      nftCreator.address,
      100,
      nftCreator.address
    );
    await nft.connect(nftCreator).safeMint(nftOwner.address, "google.com");
    expect(await nft.tokenURI(0)).to.equal("google.com");
  });

  it("conduct listing", async function () {
    // approve the marketplace for the transfer of NFT
    await nft.connect(nftOwner).approve(marketplace.address, 0);
    expect(await nft.getApproved(0)).to.equal(marketplace.address);

    // list the NFT
    await marketplace
      .connect(nftOwner)
      .createSale(nft.address, 0, payToken.address, 100);
    var res = await marketplace.getListedNFT(nft.address, 0);
    expect(res.seller).to.equal(nftOwner.address);
    expect(res.tokenId).to.equal("0");
    expect(res.price).to.equal("100");
  });

  it("smart contract storage is updated", async function () {
    var res = await marketplace.getListedNFT(nft.address, 0);
    expect(res.seller).to.equal(nftOwner.address);
    expect(res.tokenId).to.equal("0");
    expect(res.price).to.equal("100");
  });

  it("marketplace has the ownership of the listed NFT", async function () {
    expect(await nft.ownerOf(0)).to.equal(marketplace.address);
  });

  it("de-lists the listed NFT from the marketplace", async function () {
    await marketplace.connect(nftOwner).cancelListedNFT(nft.address, 0);
    expect(await nft.ownerOf(0)).to.equal(nftOwner.address);
  });
});
