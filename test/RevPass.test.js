const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RevPass", function () {
  let RevPass, revPass, ERC4907, erc4907, owner, addr1, addr2, addr3;
  const maxSupply = 1000;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();

    ERC4907 = await ethers.getContractFactory("ERC4907");
    erc4907 = await ERC4907.deploy("ERC4907Token", "ERC4907");

    RevPass = await ethers.getContractFactory("RevPass");
    revPass = await RevPass.deploy("RevPassToken", "RevPass", maxSupply);
  });

  describe("Deployment", function () {
    it("Should set the correct maxSupply", async function () {
      expect(await revPass.maxSupply()).to.equal(maxSupply);
    });

    it("Owner should be the deployer", async function () {
      expect(await revPass.owner()).to.equal(owner.address);
    });
  });

  describe("Minting", function () {
    it("Should mint tokens successfully", async function () {
      await revPass.mint(addr1.address, 123456);
      expect(await revPass.totalSupply()).to.equal(1);
      expect(await revPass.getOwnerUIN(1)).to.equal(123456);
      expect(await revPass.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should fail to mint above max supply", async function () {
      for (let i = 0; i < maxSupply; i++) {
        await revPass.mint(addr1.address, i + 1);
      }
      await expect(revPass.mint(addr1.address, maxSupply + 1)).to.be.revertedWith("RevPass__AboveMaxSupply");
    });

    it("Should only allow owner to mint", async function () {
      const revPassAsAddr1 = revPass.connect(addr1);
      await expect(revPassAsAddr1.mint(addr1.address, 123456)).to.be.reverted;
    });
  });

  describe("Mass Airdrop", function () {
    it("Should mint tokens for multiple addresses", async function () {
      const recipients = [addr1.address, addr2.address, addr3.address];
      const ownerUINs = [123456, 234567, 345678];
      await revPass.massAirdrop(recipients, ownerUINs);

      expect(await revPass.totalSupply()).to.equal(3);
      expect(await revPass.getOwnerUIN(1)).to.equal(123456);
      expect(await revPass.ownerOf(1)).to.equal(addr1.address);
      expect(await revPass.getOwnerUIN(2)).to.equal(234567);
      expect(await revPass.ownerOf(2)).to.equal(addr2.address);
      expect(await revPass.getOwnerUIN(3)).to.equal(345678);
      expect(await revPass.ownerOf(3)).to.equal(addr3.address);
    });

    it("Should only allow owner to mass airdrop", async function () {
      const revPassAsAddr1 = revPass.connect(addr1);
      const recipients = [addr1.address, addr2.address, addr3.address];
      const ownerUINs = [123456, 234567, 345678];
      await expect(revPassAsAddr1.massAirdrop(recipients, ownerUINs)).to.be.reverted;
    });
  });

  describe("Set Base URI", function () {
		it("Should set base URI successfully", async function () {
			await revPass.setBaseUri("https://example.com/metadata/");
			const uri = await revPass.tokenURI(1);
			expect(uri).to.equal("https://example.com/metadata/1.json");
		});
		
		it("Should only allow owner to set base URI", async function () {
		  const revPassAsAddr1 = revPass.connect(addr1);
		  await expect(revPassAsAddr1.setBaseUri("https://example.com/metadata/")).to.be.reverted;
		});
	});
		
	describe("Withdraw ETH", function () {
		it("Should withdraw ETH successfully", async function () {
			await owner.sendTransaction({
			to: revPass.address,
			value: ethers.utils.parseEther("1.0"),
		});

	  const balanceBefore = await owner.getBalance();
	  await revPass.withdrawETH();
	  const balanceAfter = await owner.getBalance();
	
	  expect(balanceAfter.sub(balanceBefore)).to.be.closeTo(ethers.utils.parseEther("1.0"), ethers.utils.parseEther("0.01"));
		});
	
		it("Should only allow owner to withdraw ETH", async function () {
		  const revPassAsAddr1 = revPass.connect(addr1);
		  await expect(revPassAsAddr1.withdrawETH()).to.be.reverted;
		});
	});

	describe("User and UIN Management", function () {
			beforeEach(async function () {
			await revPass.mint(addr1.address, 123456);
		});
		
		it("Should set user and user UIN successfully", async function () {
		  await revPass.connect(addr1).setUser(1, addr2.address, 1893456000, 234567);
		  expect(await revPass.userOf(1)).to.equal(addr2.address);
		  expect(await revPass.getUserUIN(1)).to.equal(234567);
		});
			
		it("Should change owner UIN successfully", async function () {
		  await revPass.changeOwnerUIN(1, 654321);
		  expect(await revPass.getOwnerUIN(1)).to.equal(654321);
		});
			
		it("Should only allow owner to change owner UIN", async function () {
		  const revPassAsAddr1 = revPass.connect(addr1);
		  await expect(revPassAsAddr1.changeOwnerUIN(1, 654321)).to.be.reverted;
		});
	});
});