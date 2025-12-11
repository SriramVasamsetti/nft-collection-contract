# nft-collection-contract

ERC-721 compatible NFT smart contract with comprehensive test suite and Docker containerization

## Overview

This project implements a fully functional NFT (Non-Fungible Token) smart contract compatible with the ERC-721 standard. It includes a complete test suite with extensive coverage and is packaged in a Docker container for reproducible testing and evaluation.

## Features

- **ERC-721 Compatibility**: Full implementation of the ERC-721 standard
- **Token Minting**: Admin-controlled minting with supply limits
- **Token Transfers**: Secure token transfer with approval mechanisms
- **Operator Approvals**: Allow operators to manage tokens on behalf of owners
- **Metadata Support**: tokenURI mechanism for token metadata
- **Token Burning**: Ability to permanently remove tokens from circulation
- **Pause/Unpause**: Admin controls to pause and unpause minting
- **Access Control**: Role-based access with admin-only functions
- **Comprehensive Testing**: 20+ test cases covering all functionality
- **Docker Ready**: Fully containerized for reproducible testing

## Project Structure

```
project-root/
├── contracts/
│   └── NftCollection.sol        # Main ERC-721 implementation
├── test/
│   └── NftCollection.test.js    # Comprehensive test suite
├── package.json                  # NPM dependencies and scripts
├── hardhat.config.js             # Hardhat configuration
├── Dockerfile                    # Docker container definition
├── .dockerignore                 # Docker ignore file
├── LICENSE                       # MIT License
└── README.md                     # This file
```

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Docker (optional, for containerized testing)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/SriramVasamsetti/nft-collection-contract.git
cd nft-collection-contract
```

2. Install dependencies:
```bash
npm install
```

3. Compile contracts:
```bash
npx hardhat compile
```

## Running Tests Locally

```bash
npm test
```

For detailed gas reports:
```bash
REPORT_GAS=true npm test
```

## Docker Usage

### Build Docker Image

```bash
docker build -t nft-contract .
```

### Run Tests in Docker

```bash
docker run nft-contract
```

## Contract Functions

### Core Functions

- `safeMint(address to, uint256 tokenId)` - Mint new token (admin only)
- `balanceOf(address owner)` - Get token count for address
- `ownerOf(uint256 tokenId)` - Get owner of specific token
- `transferFrom(address from, address to, uint256 tokenId)` - Transfer token
- `safeTransferFrom(...)` - Safe transfer with data parameter

### Approval Functions

- `approve(address to, uint256 tokenId)` - Approve address to transfer token
- `getApproved(uint256 tokenId)` - Get approved address for token
- `setApprovalForAll(address operator, bool approved)` - Set/revoke operator approval
- `isApprovedForAll(address owner, address operator)` - Check operator approval

### Admin Functions

- `pause()` - Pause minting
- `unpause()` - Unpause minting
- `burn(uint256 tokenId)` - Burn token

### View Functions

- `tokenURI(uint256 tokenId)` - Get metadata URI for token
- `name()` - Get collection name
- `symbol()` - Get collection symbol
- `maxSupply()` - Get max token supply
- `totalSupply()` - Get current total supply
- `paused()` - Check if minting is paused
- `admin()` - Get admin address

## Test Coverage

The test suite includes comprehensive coverage for:

- ✅ Deployment and initialization
- ✅ Token minting with validation
- ✅ Token transfers and approvals
- ✅ Operator approval mechanics
- ✅ Metadata URI handling
- ✅ Token burning
- ✅ Pause/unpause functionality
- ✅ Access control checks
- ✅ Event emission validation
- ✅ Edge cases and error conditions

## Security Considerations

- Admin-only functions are protected with access control modifiers
- Input validation prevents minting to zero address
- Double-minting is prevented with tokenIdExists mapping
- Approval mechanisms prevent unauthorized transfers
- Atomic state changes prevent inconsistent state
- Clear error messages for revert conditions

## Gas Optimization

- Efficient mappings for ownership tracking
- Minimal storage writes in transfer operations
- Predictable gas costs for common operations
- No unnecessary loops or complex computations

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Author

[SriramVasamsetti](https://github.com/SriramVasamsetti)
