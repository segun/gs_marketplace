const { expect } = require("chai");
const { Contract } = require("ethers");
const { ethers } = require("hardhat");
var _ = require('lodash');


describe("GS Market Place", () => {
    let erc721;
    let marketPlace;
    const mintedTokens = _.range(1001, 1005);
    let accounts;

    before(async () => {
        accounts = await ethers.getSigners();
        accounts.forEach(a => console.log(a.address));
        //1. Create the ERC721
        //3. Create the MarketPlace
        const erc721Factory = await ethers.getContractFactory("ERC721");
        erc721 = await erc721Factory.deploy();
        await erc721.deployed();
        console.log(erc721.address);
        const marketPlaceFactory = await ethers.getContractFactory("MarketPlace");
        marketPlace = await marketPlaceFactory.deploy();
        await marketPlace.deployed();
        console.log(marketPlace.address);
    });

    // after(async () => {
    //     // burn 'em tokens
    //     mintedTokens.forEach(async (t) => {
    //         console.log("Burning...");
    //         const tx = await erc721.burn(t);
    //         console.log(tx);
    //     });        
    // });

    it("should mint a couple of erc721s", async () => {
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
    });
});