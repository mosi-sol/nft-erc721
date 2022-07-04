// SPDX-License-Identifier: MIT
pragma solidity 0.8;

interface IERC2981 /*is IERC165*/ {
    /*
        tokenId 
        _salePrice  by _tokenId
        receiver
        royaltyAmount for _salePrice (10000 = 100%)
    */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// https://eips.ethereum.org/EIPS/eip-2981
/// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
/// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
