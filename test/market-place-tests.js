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

                expect(await erc721.ownerOf(t)).to.equal(accounts[index + 4].address);

                const connected = await erc721.connect(accounts[index + 4]);
                tx = await connected.approve(accounts[0].address, t);

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

            }
        } catch (error) {
            expect(error.toString()).to.contains("already minted");
        }
    });

    it("should list token for auction", async () => {
        try {
            const currentDate = new Date();
            currentDate.setDate(currentDate.getDate() - 1);
            const startDate = Math.floor(currentDate.getTime() / 1000);
            currentDate.setDate(currentDate.getDate() + 2);
            const endDate = Math.floor(currentDate.getTime() / 1000);
            const minBid = ethers.utils.parseEther("0.1");
            const listingFee = ethers.utils.parseEther("0.01");

            const connected = await marketPlace.connect(accounts[4]);
            let tx = await connected.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });

            expect(await marketPlace.isListed(erc721.address, mintedTokens[0])).to.equal(true);
        } catch (error) {
            console.log(error);
            assert(false);
        }
    });

    it("should test for listing errors", async () => {
        const currentDate = new Date();
        currentDate.setDate(currentDate.getDate() - 1);
        const startDate = Math.floor(currentDate.getTime() / 1000);
        currentDate.setDate(currentDate.getDate() + 2);
        const endDate = Math.floor(currentDate.getTime() / 1000);
        const minBid = ethers.utils.parseEther("0.1");
        let listingFee = ethers.utils.parseEther("0.001");

        const con4 = await marketPlace.connect(accounts[4]);
        try {
            let tx = await con4.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });
            console.log(tx);
        } catch (error) {
            expect(error.toString()).to.contains("pay the listing fees");
        }

        listingFee = ethers.utils.parseEther("0.01");

        const con5 = await marketPlace.connect(accounts[5]);
        try {
            let tx = await con5.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });
        } catch (error) {
            expect(error.toString()).to.contains("Not owner");
        }

        try {
            let tx = await con4.list(erc721.address, mintedTokens[0], startDate, endDate, minBid, { value: listingFee });
        } catch (error) {
            expect(error.toString()).to.contains("already started");
        }

        const sd2 = Math.floor(currentDate.getTime() * 2 / 1000);
        try {
            let tx = await con5.list(erc721.address, mintedTokens[1], sd2, endDate, minBid, { value: listingFee });
        } catch (error) {
            throw (error);
        }

        try {
            let tx = await con5.list(erc721.address, mintedTokens[1], startDate, endDate, minBid, { value: listingFee });
        } catch (error) {
            expect(error.toString()).to.contains("already listed");
        }

        const ed2 = 0;
        const con6 = await marketPlace.connect(accounts[6]);
        try {
            let tx = await con6.list(erc721.address, mintedTokens[2], startDate, ed2, minBid, { value: listingFee });
        } catch (error) {
            expect(error.toString()).to.contains("inv. end date");
        }
    });

    it("should make a bid for listed token", async () => {
        const connected = await marketPlace.connect(accounts[2]);
        const bid = ethers.utils.parseEther("0.11");
        let tx;
        const initialBalance = +ethers.utils.formatUnits(await accounts[2].getBalance());
        try {
            tx = await connected.bid(erc721.address, mintedTokens[0], { value: bid });
            const [currentBidder, currentBid, bidders, bids] = await marketPlace.getBids(erc721.address, mintedTokens[0]);
            expect(currentBidder).to.equal(accounts[2].address);
            expect(ethers.utils.formatUnits(currentBid)).to.equal("0.11");
            expect(bidders).to.be.an('array').that.includes(accounts[2].address);
            expect(bids.filter(b => ethers.utils.formatUnits(b) === "0.11")).to.be.an('array');
            const finalBalance = +ethers.utils.formatUnits(await accounts[2].getBalance());
            expect(initialBalance).to.be.greaterThan(finalBalance);
        } catch (error) {
            console.log(error);
            assert(false);
        }
    });

    it("should test for bid errors", async () => {
        const connected = await marketPlace.connect(accounts[2]);
        let bid = ethers.utils.parseEther("0.01");
        let tx;
        try {
            tx = await connected.bid(erc721.address, mintedTokens[0], { value: bid });
        } catch (error) {
            expect(error.toString()).to.contains("too low");
        }

        bid = ethers.utils.parseEther("0.11");
        try {
            tx = await connected.bid(erc721.address, mintedTokens[1], { value: bid });
        } catch (error) {
            expect(error.toString()).to.contains("not started");
        }

        try {
            tx = await connected.bid(erc721.address, 1234, { value: bid });
        } catch (error) {
            expect(error.toString()).to.contains("not listed");
        }
    });
});