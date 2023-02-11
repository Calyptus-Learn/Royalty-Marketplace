const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Test to accept sale at alternate offered price:", function () {
  // Actors
  let payTokenDeployer, marketplaceOwner, nftCreator, nftOwner, nftBuyer;

  // Smart contracts
  let marketplace, payToken, nft;

  before(async function () {
    [payTokenDeployer, marketplaceOwner, nftCreator, nftOwner, nftBuyer] =
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
      1000,
      nftCreator.address
    );
    await nft.connect(nftCreator).safeMint(nftOwner.address, "google.com");
    expect(await nft.tokenURI(0)).to.equal("google.com");

    // approve the marketplace for the transfer of NFT
    await nft.connect(nftOwner).approve(marketplace.address, 0);
    expect(await nft.getApproved(0)).to.equal(marketplace.address);

    // list the NFT
    await marketplace
      .connect(nftOwner)
      .createSale(nft.address, 0, payToken.address, 100);
    const res = await marketplace.getListedNFT(nft.address, 0);
    expect(res.seller).to.equal(nftOwner.address);
    expect(res.tokenId).to.equal("0");
    expect(res.price).to.equal("100");
  });

  it("Offerer makes offer, Lister accepts offer", async function () {
    // Equivalent of NFT buyer getting ERC20 token to make offer
    await payToken.connect(payTokenDeployer).mint(nftBuyer.address, 50);

    // Buyer approves marketplace to spend the fee
    await payToken.connect(nftBuyer).approve(marketplace.address, 50);

    // Buyer makes an offer at half the listed price
    await marketplace.connect(nftBuyer).makeOffer(nft.address, 0, 50);

    // NFT owner accepts the offer
    await marketplace
      .connect(nftOwner)
      .acceptOffer(nft.address, 0, nftBuyer.address);
  });

  it("buyer has the NFT", async function () {
    expect(await nft.ownerOf(0)).to.equal(nftBuyer.address);
  });

  it("previous owner does not have the NFT any more", async function () {
    expect(await nft.ownerOf(0)).to.not.equal(nftOwner);
  });

  it("previous owner got the price", async function () {
    expect(await payToken.balanceOf(nftOwner.address)).to.equal(40);
  });

  it("marketplace got the fee", async function () {
    expect(await payToken.balanceOf(marketplaceOwner.address)).to.equal(5);
  });

  it("Creator got the royalty", async function () {
    expect(await payToken.balanceOf(nftCreator.address)).to.equal(5);
  });
});
