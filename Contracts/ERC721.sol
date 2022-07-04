// SPDX-License-Identifier: MIT
pragma solidity 0.8;
// https://eips.ethereum.org/EIPS/eip-721

// dev shadow protection: 
// local var = _xyz  -  satate var = xyz_  -  other var = xyz || XYZ
// pub/ext func = xyz()  -  priv/int func = _xyz()

// almost marcketplaces need => ownable + ierc165 => for connect to nft`s

// --- requirments ---
import "./IERC165.sol";
import "./IERC721.sol";
import "./IERC721TokenReceiver.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC2981.sol";
// --- libs ---
import "./MATH.sol";
import "./ADDRESS.sol";
import "./OWNABLE.sol";

abstract contract ERC721 is IERC165, IERC721, IERC721TokenReceiver, IERC721Metadata, IERC721Enumerable, IERC2981, Ownable {
    // lib's =====================================================================
    using MATH for uint256;
    using ADDRESS for address;

    // variables =====================================================================
    string private name_;       // NFT NAME
    string private symbol_;     // NFT SYMBOL
    string private baseURI_;    // core uri
    uint256 private tokenId_;   // iterat minted token`s
    uint256 private total_;     // total token`s
    uint256 private globalRoyality_; // between 0 to 10
    bool private isGlobalRoyality_ = false; // security check

    mapping(address => uint256) private balanceOf_;         // owner -> token`s 
    mapping(uint256 => address) private ownerOf_;           // token ID -> owner
    mapping(uint256 => string) private tokenURI_;           // token ID -> uri
    mapping(uint256 => address) private approval_;          // token ID -> approved address
    mapping(address => mapping(address => bool)) private allowance_; // owner -> operator -> approvals
    mapping(uint256 => uint256) private royalties_; // 10000 = 100% - 1000 = 10% - 100 = 1%

    // yells =====================================================================
    event RoyalityChange(uint256 indexed tokenId, uint256 percent, uint256 time);

    // validators =====================================================================
    modifier exist(uint256 _tokenId) {
        _exist(_tokenId);
        _;
    }

    // validators conterbut =====================================================================
    function _exist(uint256 _tokenId) internal view {
        ownerOf_[_tokenId] != address(0);
    }

    // initial =====================================================================
    constructor(
        string memory __name,
        string memory __symbol,
        uint256 __globalRoyality
    ) {
        name_ = __name;
        symbol_ = __symbol;
        tokenId_ = 0;
        if(__globalRoyality <= 10){globalRoyality_ = __globalRoyality;}
        __globalRoyality <= 10 ? globalRoyality_ = __globalRoyality : globalRoyality_ = 0;
    }

    // register =====================================================================
    function supportsInterface(bytes4 interfaceId) external virtual override view returns (bool) {
        return interfaceId == type(IERC165).interfaceId || 
        interfaceId == type(IERC721).interfaceId || 
        interfaceId == type(IERC721TokenReceiver).interfaceId || 
        interfaceId == type(IERC721Metadata).interfaceId || 
        interfaceId == type(IERC721Enumerable).interfaceId ||
        interfaceId == type(IERC2981).interfaceId;
    }

    // calculations / logics =====================================================================
    function name() external virtual override view returns (string memory _name) {
        _name = name_;
    }

    function symbol() external virtual override view returns (string memory _symbol) {
       _symbol = symbol_;
    }

    function tokenURI(uint256 _tokenId) external virtual override view returns (string memory) {
        return tokenURI_[_tokenId];
    }

    function balanceOf(address _owner) external virtual override view returns (uint256) {
        return balanceOf_[_owner];
    }

    function ownerOf(uint256 _tokenId) external virtual override view returns (address) {
        return ownerOf_[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transfer(_from, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable virtual override {
        require(_isApprovedForAll(ownerOf_[_tokenId],_from) || _from == ownerOf_[_tokenId], "ERROR: transfer would from the owner or approved");
        _transfer(_from, _to, _tokenId);
    }
    
    function transfer(address _to, uint256 _tokenId) external payable virtual returns (bool) {
        _transfer(_msgSender(), _to, _tokenId);
        return true;
    }

    function approve(address _approved, uint256 _tokenId) external payable exist(_tokenId) virtual override {
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only owner of token");
        require(_msgSender() != _approved, "ERROR: owner was approved");
        approval_[_tokenId] = _approved;
        emit Approval(_msgSender(), _approved, _tokenId);
    }

    // setApprovalForAll function is a bug in ethereum, controling whole your nft`s to anonymus sign in frontend
    function setApprovalForAll(address _operator, bool _approved) external virtual override {
        require(_msgSender() != _operator, "ERROR: approve to not owner");
        allowance_[_msgSender()][_operator] = _approved;
        emit ApprovalForAll(_msgSender(), _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external exist(_tokenId) virtual override view returns (address) {
        return approval_[_tokenId];
    }

    function _isApprovedForAll(address _owner, address _operator) internal virtual view returns (bool) {
       return allowance_[_owner][_operator];
    }

    function isApprovedForAll(address _owner, address _operator) external virtual override view returns (bool) {
       return allowance_[_owner][_operator];
    }

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external virtual override returns(bytes4) {
        // use: _checkOnERC721Received in transfer functions
    }

    // if add MAX in your contract, total can not be higer then the maimum supply
    function totalSupply() external virtual override view returns (uint256) {
        return total_;
    }
    
    // royality set-update/get/delete & royaltyInfo + change isGlobalRoyality_ status - have 5 functions
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external exist(_tokenId) virtual override view returns (address _receiver, uint256 _royaltyAmount){
        // 10000 = 100% - 1000 = 10% - 100 = 1% -> we need 100\10% to 10\1%
        isGlobalRoyality_ == false ? 
            _royaltyAmount = (_salePrice * royalties_[_tokenId]) / 10000 : 
            _royaltyAmount = (_salePrice * globalRoyality_) / 10000;
        _receiver = ownerOf_[_tokenId];
    }

    function globalRoyalityStatus() external onlyOwner virtual {
        isGlobalRoyality_ != isGlobalRoyality_;
    }

    function setRoyaltyPercent(uint256 _tokenId, uint256 _percent) external exist(_tokenId) virtual {
        require(_isApprovedForAll(ownerOf_[_tokenId], _msgSender()) || _msgSender() == ownerOf_[_tokenId], "ERROR: would from the owner or approved");
        if(_percent < 1000 && _percent >= 0){
            royalties_[_tokenId] = _percent;
            emit RoyalityChange(_tokenId, _percent, block.timestamp);
        } else {
            revert("ERROR: not more then 10% for royality, invest on your talents");
        }
    }

    function getRoyaltyPercent(uint256 _tokenId) external exist(_tokenId) virtual returns (uint256) {
        return royalties_[_tokenId];
    }

    function removeRoyaltyPercent(uint256 _tokenId) external exist(_tokenId) virtual {
        royalties_[_tokenId] = 0;
        emit RoyalityChange(_tokenId, 0, block.timestamp);
    }

    /*
    for indexing need alot of gas, watch below for conditions & functions : 
    Conditions: from == address(0) -- from != to -- to == address(0) -- to != from 
    call index funcs in --> _beforeTransfer(...)  &  _afterTransfer(...) --> by using conditions as a helper
    ** so i no recomend to use, but just use conditions if you like to use **
    */
    // tokenByIndex => more gas spending
    function tokenByIndex(uint256 _index) external virtual override view returns (uint256) {

    }

    // tokenOfOwnerByIndex => more gas spending
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external virtual override view returns (uint256) {

    }

    // logic`s =====================================================================
    function _transfer(address _from, address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(ownerOf_[_tokenId] == _from, "ERROR: why spen gas!");
        require(_to != address(0), "ERROR: black hole not accepted");
        _beforeTransfer(_from, _to, _tokenId);
        _approve(address(0), _tokenId);
        balanceOf_[_from] -= 1;
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
        _afterTransfer(_from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) internal exist(_tokenId) virtual {
        _transfer(_from, _to, _tokenId);
        require(_checkOnERC721Received(_from, _to, _tokenId, _data), "ERROR: transfer to not accepted ERC721Receiver wallet/contract");
    }    

    function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) internal exist(_tokenId) virtual {
        _transferFrom(_from, _to, _tokenId, _data);
    }

    function _approve(address _approved, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only owner of token");
        require(_msgSender() != _approved, "ERROR: owner was approved");
        approval_[_tokenId] = _approved;
        emit Approval(_msgSender(), _approved, _tokenId);
    }

    // setup uri setting =====================================================================
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI_;
    }

    function _setURI(string calldata _uri) internal virtual {
        baseURI_ = _uri;
    }

    function _setTokenURI(string calldata _uri, uint256 _tokenId) internal exist(_tokenId) virtual {
        tokenURI_[_tokenId] = _uri;
    }
    
    function _tokenURI(uint256 _tokenId, string calldata _prefix) internal exist(_tokenId) view virtual returns (string memory) {
        string memory _URI = _baseURI();
        return bytes(_URI).length > 0
            ? string(abi.encodePacked(_URI, _tokenId.toString(), _prefix))
            : "";
    }

    // tools =====================================================================
    // ERC721 Holder | trackable
     function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes memory _data) internal virtual returns (bool) {
        if (_to.isContract()) {
            try IERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 _returnval) {
                return _returnval == IERC721TokenReceiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) { revert("ERROR: transfer to non ERC721Receiver implementer"); } 
                else { assembly { revert(add(32, reason), mload(reason)) } }
            }
        } else {
            return true;
        }
    }

    function _currentId() internal view virtual returns (uint256) {
        return tokenId_;
    }

    //*************************************************************************************************
    function _safeMint(address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        _safeMint(_to, _tokenId, "");
    }

    function _safeMint(address _to, uint256 _tokenId, bytes memory _data) internal exist(_tokenId) virtual {
        _mint(_to, _tokenId);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "ERROR: transfer to not accepted ERC721Receiver wallet/contract"
        );
    }
    
    function _safeMint(address _to, uint256 _tokenId, string calldata _uri) internal exist(_tokenId) virtual {
        _safeMint(_to, _tokenId, _uri, "");
    }

    function _safeMint(address _to, uint256 _tokenId, string calldata _uri, bytes memory _data) internal exist(_tokenId) virtual {
        _mint(_to, _tokenId, _uri);
        require(
            _checkOnERC721Received(address(0), _to, _tokenId, _data),
            "EERROR: transfer to not accepted ERC721Receiver wallet/contract"
        );
    }

    function _mint(address _to, uint256 _tokenId) internal exist(_tokenId) virtual {
        require(_to != address(0), "ERROR: mint to black hole!");
        _beforeTransfer(address(0), _to, _tokenId);
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        total_ += 1;
        royalties_[_tokenId] = globalRoyality_;
        emit Transfer(address(0), _to, _tokenId);
        _afterTransfer(address(0), _to, _tokenId);
    }

    function _mint(address _to, uint256 _tokenId, string calldata _uri) internal exist(_tokenId) virtual {
        require(_to != address(0), "ERROR: mint to black hole!");
        _beforeTransfer(address(0), _to, _tokenId);
        balanceOf_[_to] += 1;
        ownerOf_[_tokenId] = _to;
        _setTokenURI(_uri, _tokenId);
        total_ += 1;
        royalties_[_tokenId] = globalRoyality_;
        emit Transfer(address(0), _to, _tokenId);
        _afterTransfer(address(0), _to, _tokenId);
    }


    function mint(address _to, uint256 _tokenId) external payable virtual {
        _safeMint(_to, _tokenId);
    }

    function mint() external payable virtual {
        _safeMint(_msgSender(), tokenId_++);
    }

    function mint(string calldata _uri) external payable virtual {
        _safeMint(_msgSender(), tokenId_++, _uri);
    }

    // burn
    function _burn(uint256 _tokenId) internal exist(_tokenId) virtual {
        require(ownerOf_[_tokenId] != address(0), "ERROR: only existed item");
        require(_msgSender() == ownerOf_[_tokenId], "ERROR: only token owner");
        _beforeTransfer(_msgSender(), address(0), _tokenId);
        _approve(address(0), _tokenId);
        balanceOf_[_msgSender()] -= 1;
        ownerOf_[_tokenId] = address(0); // delete ownerOf_[_tokenId];
        
        if (bytes(tokenURI_[_tokenId]).length != 0) {
            delete tokenURI_[_tokenId];
        }

        emit Transfer(_msgSender(), address(0), _tokenId);
        _afterTransfer(_msgSender(), address(0), _tokenId);
    }

    function burn(uint256 _tokenId) external payable virtual {
        _burn(_tokenId);
    }

    //*************************************************************************************************

    // empty tester/validator
    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual {}
    function _afterTransfer(address from, address to, uint256 tokenId) internal virtual {}
    /* Conditions: from == address(0) -- from != to -- to == address(0) -- to != from */

    // helper =====================================================================
    function _this() internal view virtual returns (address) {
        return address(this);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint) {
        return msg.value;
    }

    /* =============================================
                    --- ERC721 ---
    ================================================
            creator :       mosi
            version :       1.0.2022
            email :         mosipvp@gmail.com
            linkedin :      moslem-abbasi
            github :        mosi-sol
    ================================================
            fully functional NFT ERC721
    ================================================
    how to use : following this folder -> mock.sol
                    suggestion : 
    ================================================
        split each functional point to use in 
        your projects. absolutly for less gas.
    ===============================================*/
    

}
