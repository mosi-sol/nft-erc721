// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import "./ERC721.sol";

// NFT MOCK
contract NFT is ERC721 {
    uint count;
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 __globalRoyality
    ) ERC721(__name, __symbol, __globalRoyality) {
        count = 0;
        __globalRoyality = 1000;
    }

    // this important for market places + owner funcions
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == type(ERC721).interfaceId;
    }

    function mint() external payable virtual override {
        _safeMint(_msgSender(), count);
        unchecked { count += 1; }
    }

    function mint(string calldata _uri) external payable virtual override {
        _safeMint(_msgSender(), count, _uri);
        unchecked { count += 1; }
    }

    function burn(uint256 _tokenId) external payable virtual override {
        _burn(_tokenId);
    }
}
