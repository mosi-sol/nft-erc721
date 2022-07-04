// SPDX-License-Identifier: MIT
pragma solidity 0.8;

abstract contract Ownable {
    address private owner_;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  
    constructor() {
        _transferOwnership(msg.sender);
    }

  
    function owner() public view virtual returns (address) {
        return owner_;
    }


    modifier onlyOwner() {
        require(owner() == msg.sender, "ERROR: caller is not the owner");
        _;
    }

   
    function renounceOwnership() public virtual onlyOwner {
        // _transferOwnership(address(0));
        _transferOwnership(address(this)); // immortality
    }

  
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERROR: new owner can not zero address");
        _transferOwnership(newOwner);
    }

 
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner_;
        owner_ = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
