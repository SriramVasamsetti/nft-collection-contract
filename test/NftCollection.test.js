const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('NftCollection', function () {
  let nftCollection;
  let owner, addr1, addr2;
  const TOKEN_NAME = 'TestNFT';
  const TOKEN_SYMBOL = 'TNFT';
  const MAX_SUPPLY = 100;
  const BASE_URI = 'https://example.com/metadata/';

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const NftCollection = await ethers.getContractFactory('NftCollection');
    nftCollection = await NftCollection.deploy(TOKEN_NAME, TOKEN_SYMBOL, MAX_SUPPLY, BASE_URI);
    await nftCollection.waitForDeployment();
  });

  describe('Deployment', function () {
    it('Should set correct initial values', async function () {
      expect(await nftCollection.name()).to.equal(TOKEN_NAME);
      expect(await nftCollection.symbol()).to.equal(TOKEN_SYMBOL);
      expect(await nftCollection.maxSupply()).to.equal(MAX_SUPPLY);
      expect(await nftCollection.totalSupply()).to.equal(0);
      expect(await nftCollection.admin()).to.equal(owner.address);
      expect(await nftCollection.paused()).to.equal(false);
    });
  });

  describe('Minting', function () {
    it('Should mint successfully', async function () {
      await nftCollection.safeMint(addr1.address, 1);
      expect(await nftCollection.ownerOf(1)).to.equal(addr1.address);
      expect(await nftCollection.balanceOf(addr1.address)).to.equal(1);
      expect(await nftCollection.totalSupply()).to.equal(1);
    });

    it('Should emit Transfer on mint', async function () {
      await expect(nftCollection.safeMint(addr1.address, 1)).to.emit(nftCollection, 'Transfer');
    });

    it('Admin only', async function () {
      await expect(nftCollection.connect(addr1).safeMint(addr1.address, 1))
        .to.be.revertedWith('Only admin');
    });

    it('No zero address', async function () {
      await expect(nftCollection.safeMint(ethers.ZeroAddress, 1))
        .to.be.revertedWith('Cannot mint to zero');
    });

    it('No double mint', async function () {
      await nftCollection.safeMint(addr1.address, 1);
      await expect(nftCollection.safeMint(addr2.address, 1))
        .to.be.revertedWith('Token already exists');
    });

    it('Respect max supply', async function () {
      const nft = await (await ethers.getContractFactory('NftCollection'))
        .deploy('S', 'S', 1, BASE_URI);
      await nft.waitForDeployment();
      await nft.safeMint(addr1.address, 1);
      await expect(nft.safeMint(addr2.address, 2))
        .to.be.revertedWith('Max supply');
    });

    it('Reject tokenId 0', async function () {
      await expect(nftCollection.safeMint(addr1.address, 0))
        .to.be.revertedWith('Token ID must be greater');
    });
  });

  describe('Transfers', function () {
    beforeEach(async function () {
      await nftCollection.safeMint(owner.address, 1);
      await nftCollection.safeMint(addr1.address, 2);
    });

    it('Transfer token', async function () {
      await nftCollection.transferFrom(owner.address, addr2.address, 1);
      expect(await nftCollection.ownerOf(1)).to.equal(addr2.address);
      expect(await nftCollection.balanceOf(owner.address)).to.equal(0);
      expect(await nftCollection.balanceOf(addr2.address)).to.equal(1);
    });

    it('Emit Transfer', async function () {
      await expect(nftCollection.transferFrom(owner.address, addr2.address, 1))
        .to.emit(nftCollection, 'Transfer');
    });

    it('Authorization check', async function () {
      await expect(nftCollection.connect(addr2).transferFrom(owner.address, addr2.address, 1))
        .to.be.revertedWith('Not authorized');
    });

    it('Approved transfer', async function () {
      await nftCollection.approve(addr2.address, 1);
      await nftCollection.connect(addr2).transferFrom(owner.address, addr2.address, 1);
      expect(await nftCollection.ownerOf(1)).to.equal(addr2.address);
    });

    it('Operator transfer', async function () {
      await nftCollection.setApprovalForAll(addr2.address, true);
      await nftCollection.connect(addr2).transferFrom(owner.address, addr2.address, 1);
      expect(await nftCollection.ownerOf(1)).to.equal(addr2.address);
    });
  });

  describe('Approvals', function () {
    beforeEach(async function () {
      await nftCollection.safeMint(owner.address, 1);
    });

    it('Approve', async function () {
      await nftCollection.approve(addr1.address, 1);
      expect(await nftCollection.getApproved(1)).to.equal(addr1.address);
    });

    it('Approval event', async function () {
      await expect(nftCollection.approve(addr1.address, 1)).to.emit(nftCollection, 'Approval');
    });

    it('Operator approval', async function () {
      await nftCollection.setApprovalForAll(addr1.address, true);
      expect(await nftCollection.isApprovedForAll(owner.address, addr1.address)).to.be.true;
    });
  });

  describe('Metadata', function () {
    beforeEach(async function () {
      await nftCollection.safeMint(addr1.address, 1);
    });

    it('TokenURI', async function () {
      const uri = await nftCollection.tokenURI(1);
      expect(uri).to.equal(BASE_URI + '1');
    });

    it('Invalid token URI', async function () {
      await expect(nftCollection.tokenURI(999))
        .to.be.revertedWith('does not exist');
    });
  });

  describe('Burning', function () {
    beforeEach(async function () {
      await nftCollection.safeMint(owner.address, 1);
    });

    it('Burn', async function () {
      await nftCollection.burn(1);
      expect(await nftCollection.totalSupply()).to.equal(0);
      expect(await nftCollection.balanceOf(owner.address)).to.equal(0);
    });

    it('Burn event', async function () {
      await expect(nftCollection.burn(1)).to.emit(nftCollection, 'Transfer');
    });

    it('Owner only', async function () {
      await expect(nftCollection.connect(addr1).burn(1))
        .to.be.revertedWith('Only token owner');
    });
  });

  describe('Admin', function () {
    it('Pause', async function () {
      await nftCollection.pause();
      expect(await nftCollection.paused()).to.be.true;
      await expect(nftCollection.safeMint(addr1.address, 1))
        .to.be.revertedWith('paused');
    });

    it('Unpause', async function () {
      await nftCollection.pause();
      await nftCollection.unpause();
      expect(await nftCollection.paused()).to.be.false;
      await nftCollection.safeMint(addr1.address, 1);
      expect(await nftCollection.totalSupply()).to.equal(1);
    });
  });
});
