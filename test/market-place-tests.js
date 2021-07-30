const { expect, assert } = require("chai");
const { Contract } = require("ethers");
const { ethers } = require("hardhat");
var _ = require('lodash');


describe("GS Market Place", () => {
    let erc721;
    let marketPlace;
    const mintedTokens = _.range(1001, 1005);
    let accounts;
    const address0 = "0x0000000000000000000000000000000000000000";

    before(async () => {
        accounts = await ethers.getSigners();
        // accounts.forEach(a => console.log(a.address));
        const erc721Factory = await ethers.getContractFactory("ERC721");
        erc721 = await erc721Factory.deploy();
        await erc721.deployed();
        console.log(`ERC721: ${erc721.address}`);
        const marketPlaceFactory = await ethers.getContractFactory("MarketPlace");
        marketPlace = await marketPlaceFactory.deploy();
        await marketPlace.deployed();
        console.log(`Market Place: ${marketPlace.address}`);
    });

    // after(async () => {
    //     // burn 'em tokens
    //     for (let index = 0; index < mintedTokens.length; index++) {
    //         const t = mintedTokens[index];
    //         console.log("Burning...");
    //         const tx = await erc721.burn(t);
    //         tx.wait(2);
    //         expect(await erc721.ownerOf(t)).to.equal(address0);
    //     };
    // });

    it("should mint a couple of erc721s", async () => {
        try {
            for (let index = 0; index < mintedTokens.length; index++) {
                const t = mintedTokens[index];
                let tx = await erc721.mint(accounts[index + 4].address, t);
                tx.wait(2);
                expect(await erc721.ownerOf(t)).to.equal(accounts[index + 4].address);

                const connected = await erc721.connect(accounts[index + 4]);
                tx = await connected.approve(accounts[0].address, t);
                tx.wait(2);
                expect(await erc721.getApproved(t)).to.equal(accounts[0].address);
            }
        } catch (error) {
            console.log(error);
            assert(false);
        }
    });

    it("should not mint already", async () => {
        try {
            for (let index = 0; index < mintedTokens.length; index++) {
                const t = mintedTokens[index];
                let tx = await erc721.mint(accounts[index + 4].address, t);
                tx.wait(2);
            }
        } catch (error) {
            expect(error.toString()).to.contains("already minted");
        }
    });

    it("should list token for auction", async () => {
        try {
            const currentDate = new Date();
            currentDate.setDate(currentDate.getDate() + 1);
            const startDate = Math.floor(currentDate.getTime() / 1000);
            currentDate.setDate(currentDate.getDate() + 1);
            const endDate = Math.floor(currentDate.getTime() / 1000);
            const minBid = ethers.utils.parseEther("0.1");
            const listingFee = ethers.utils.parseEther("0.01");

            const connected = await marketPlace.connect(accounts[4]);
            let tx = await connected.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });
            tx.wait(2);
            expect(await marketPlace.isListed(erc721.address, mintedTokens[0])).to.equal(true);
        } catch (error) {
            console.log(error);
            assert(false);
        }
    });

    it("should not list token for auction if already listed", async () => {
        try {
            const currentDate = new Date();
            currentDate.setDate(currentDate.getDate() + 1);
            const startDate = Math.floor(currentDate.getTime() / 1000);
            currentDate.setDate(currentDate.getDate() + 1);
            const endDate = Math.floor(currentDate.getTime() / 1000);
            const minBid = ethers.utils.parseEther("0.1");
            const listingFee = ethers.utils.parseEther("0.01");

            const connected = await marketPlace.connect(accounts[4]);
            let tx = await connected.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });
            tx.wait(2);
        } catch (error) {
            expect(error.toString()).to.contains("already listed");
        }
    });
});