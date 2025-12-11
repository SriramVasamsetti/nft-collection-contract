// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NftCollection
 * @dev ERC-721 compatible NFT smart contract with comprehensive functionality
 */
contract NftCollection {
    // ============ State Variables ============
    
    string public name;
    string public symbol;
    uint256 public maxSupply;
    uint256 public totalSupply;
    bool public paused;
    address public admin;
    string private baseURI;
    
    // Mappings
    mapping(uint256 => address) private tokenIdToOwner;
    mapping(address => uint256) private ownerToBalance;
    mapping(uint256 => address) private tokenIdToApproved;
    mapping(address => mapping(address => bool)) private ownerToOperatorApprovals;
    mapping(uint256 => bool) private tokenIdExists;
    
    // ============ Events ============
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Paused();
    event Unpaused();
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }
    
    modifier tokenExists(uint256 tokenId) {
        require(tokenIdExists[tokenId], "Token does not exist");
        _;
    }
    
    // ============ Constructor ============
    
    constructor(string memory _name, string memory _symbol, uint256 _maxSupply, string memory _baseURI) {
        require(_maxSupply > 0, "Max supply must be greater than 0");
        name = _name;
        symbol = _symbol;
        maxSupply = _maxSupply;
        baseURI = _baseURI;
        admin = msg.sender;
        paused = false;
        totalSupply = 0;
    }
    
    // ============ Public Functions ============
    
    /**
     * @dev Returns the number of tokens owned by an address
     */
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Cannot query zero address");
        return ownerToBalance[owner];
    }
    
    /**
     * @dev Returns the owner of a specific tokenId
     */
    function ownerOf(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenIdToOwner[tokenId];
    }
    
    /**
     * @dev Mints a new NFT token
     */
    function safeMint(address to, uint256 tokenId) public onlyAdmin whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(!tokenIdExists[tokenId], "Token already exists");
        require(totalSupply < maxSupply, "Max supply exceeded");
        require(tokenId > 0, "Token ID must be greater than 0");
        
        tokenIdToOwner[tokenId] = to;
        ownerToBalance[to] += 1;
        tokenIdExists[tokenId] = true;
        totalSupply += 1;
        
        emit Transfer(address(0), to, tokenId);
    }
    
    /**
     * @dev Transfers a token from one address to another
     */
    function transferFrom(address from, address to, uint256 tokenId) public tokenExists(tokenId) {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        require(tokenIdToOwner[tokenId] == from, "From address is not the owner");
        
        require(
            msg.sender == from || 
            msg.sender == tokenIdToApproved[tokenId] || 
            ownerToOperatorApprovals[from][msg.sender],
            "Not authorized to transfer"
        );
        
        if (tokenIdToApproved[tokenId] != address(0)) {
            tokenIdToApproved[tokenId] = address(0);
            emit Approval(from, address(0), tokenId);
        }
        
        tokenIdToOwner[tokenId] = to;
        ownerToBalance[from] -= 1;
        ownerToBalance[to] += 1;
        
        emit Transfer(from, to, tokenId);
    }
    
    /**
     * @dev Safe transfer with data parameter
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
    }
    
    /**
     * @dev Safe transfer without data parameter
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    /**
     * @dev Approves an address to transfer a specific token
     */
    function approve(address to, uint256 tokenId) public tokenExists(tokenId) {
        address owner = tokenIdToOwner[tokenId];
        require(msg.sender == owner || ownerToOperatorApprovals[owner][msg.sender], 
                "Not authorized to approve");
        
        tokenIdToApproved[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    /**
     * @dev Sets or revokes operator approval for all tokens
     */
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Cannot approve yourself");
        
        ownerToOperatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    /**
     * @dev Returns the approved address for a token
     */
    function getApproved(uint256 tokenId) public view tokenExists(tokenId) returns (address) {
        return tokenIdToApproved[tokenId];
    }
    
    /**
     * @dev Checks if an operator is approved for all tokens of an owner
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return ownerToOperatorApprovals[owner][operator];
    }
    
    /**
     * @dev Returns the metadata URI for a token
     */
    function tokenURI(uint256 tokenId) public view tokenExists(tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, uint2str(tokenId)));
    }
    
    /**
     * @dev Pauses minting
     */
    function pause() public onlyAdmin {
        paused = true;
        emit Paused();
    }
    
    /**
     * @dev Unpauses minting
     */
    function unpause() public onlyAdmin {
        paused = false;
        emit Unpaused();
    }
    
    /**
     * @dev Burns a token
     */
    function burn(uint256 tokenId) public tokenExists(tokenId) {
        address owner = tokenIdToOwner[tokenId];
        require(msg.sender == owner, "Only token owner can burn");
        
        if (tokenIdToApproved[tokenId] != address(0)) {
            tokenIdToApproved[tokenId] = address(0);
            emit Approval(owner, address(0), tokenId);
        }
        
        tokenIdToOwner[tokenId] = address(0);
        ownerToBalance[owner] -= 1;
        tokenIdExists[tokenId] = false;
        totalSupply -= 1;
        
        emit Transfer(owner, address(0), tokenId);
    }
    
    // ============ Internal Helper Functions ============
    
    /**
     * @dev Converts uint to string
     */
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}
