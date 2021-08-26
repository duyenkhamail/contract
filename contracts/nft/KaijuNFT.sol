pragma solidity ^0.8.0;
import "../interfaces/INFT.sol";
import "../libs/StringsHelper.sol";
import "../libs/RoleDefine.sol";
// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract KaijuNFT is
    Initializable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    INFT
{
    bool private locked;
    modifier lock {
        require(locked == false, "KAIJU: LOCKING");
        locked = true;
        _;
        locked = false;
    }
    using SafeMath for uint256;
    using StringsHelper for uint256;
    using StringsHelper for address;
    address public routerAddress;
    string public nftType;
    uint256 public price;
    string public baseUri;
    mapping(uint256 => uint256[]) public tokensOfType;
    mapping(uint256 => uint256) public maxOfType;
    mapping(uint256 => uint256) public totalOfType;
    mapping(uint256 => uint256) public nonce;
    mapping(uint256 => TokenAttributes) allTokenAttributes;
    event MintNFT(address _account, uint256 _tokenId);
    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _type
    ) public initializer {
        initNFT(_name, _symbol, _type);
    }

    function initNFT(
        string memory _name,
        string memory _symbol,
        string memory _type
    ) public {
        __ERC721_init(_name, _symbol);
        nftType = _type;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RoleDefine.PLATFORM_ROUTER, msg.sender);
        // nonce = 0;
        baseUri = "https://data.kaijuworlds.io/nft/";
        locked = false;
    }

    modifier restrictAdmin {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "KaijuNFT: NOT ADMIN");
        _;
    }
    modifier restrictRouter {
        require(
            hasRole(RoleDefine.PLATFORM_ROUTER, msg.sender),
            "KaijuNFT: NOT ROUTER"
        );
        _;
    }

    function grantRouter(address _router) external restrictAdmin {
        grantRole(RoleDefine.PLATFORM_ROUTER, _router);
    }


    function increaseNFTCount(uint256 _idInType, uint256 _num)
        external
        override
        restrictRouter
    {
        maxOfType[_idInType] = maxOfType[_idInType].add(_num);
    }

    function setMaxNFTCounts(uint256[] memory ids, uint256[] memory _maxNumbers)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            maxOfType[ids[i]] = _maxNumbers[i];
        }
    }

    function setMaxNFTCount(uint256 _typeId, uint256 _maxNumbers)
        external
        restrictAdmin
    {
        maxOfType[_typeId] = _maxNumbers;
    }

    function getTotalNFT(uint256 _typeId)
        external
        view
        override
        returns (uint256)
    {
        return totalOfType[_typeId];
    }

    function burnNFT(address account, uint256 id)
        external
        override
        restrictRouter
    {
        _transfer(account, 0x000000000000000000000000000000000000dEaD, id);
    }

    function mintNFT(
        address account,
        uint256 _typeId,
        uint256 _rarity,
        uint256 _quality
    )
        external
        virtual
        override
        restrictRouter
        lock
        returns (
            bool openResult,
            string memory message,
            uint256 tokenId
        )
    {
        // if (totalOfType[_typeId] >= maxOfType[_typeId]) {
        //     openResult = false;
        //     message = string(
        //         abi.encodePacked(
        //             "THIS PACK TYPE IS OVER LIMIT ",
        //             maxOfType[_typeId].toString()
        //         )
        //     );
        // } else {
            openResult = true;
            message = string(abi.encodePacked("OPEN NFT SUCCESS"));
            totalOfType[_typeId] = totalOfType[_typeId].add(1);
            tokenId = totalSupply().add(1);
            TokenAttributes memory attributes = TokenAttributes(
                tokenId,
                totalOfType[_typeId],
                _typeId,
                _rarity,
                _quality
            );
            allTokenAttributes[tokenId] = attributes;
            tokensOfType[_typeId].push(tokenId);
            _mint(account, tokenId);
        // }
    }
    function getTokensOfType(uint256 _type)
        external
        view
        returns (uint256[] memory)
    {
        return tokensOfType[_type];
    }

    function getType() external view override returns (string memory) {
        return nftType;
    }

    function getTokenAttributes(uint256 _tokenId)
        external
        view
        override
        returns (TokenAttributes memory)
    {
        return allTokenAttributes[_tokenId];
    }

    function setPrice(uint256 _price) external override restrictAdmin {
        price = _price;
    }

    function getPrice() external view override returns (uint256 _price) {
        return price;
    }

    function maxSupply(uint256 _typeId)
        public
        view
        override
        returns (uint256)
    {
        return maxOfType[_typeId];
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        TokenAttributes memory attributes = allTokenAttributes[tokenId];
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI,
                        nftType,
                        "/",
                        attributes.TypeId.toString(),
                        "/",
                        // address(this).toString(),
                        // "/",
                        tokenId.toString(),
                        "/",
                        attributes.Rarity.toString(),
                        "/",
                        attributes.Quality.toString()
                    )
                )
                : "";
    }

    function setBaseUri(string memory _uri) external override restrictRouter {
        baseUri = _uri;
    }

    function setBaseUriByAdmin(string memory _uri) external restrictAdmin {
        baseUri = _uri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function getTokensWithUriOfOwner(address _owner)
        external
        view
        override
        returns (uint256[] memory _ids, string[] memory _uri)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            _ids = new uint256[](0);
            _uri = new string[](0);
        } else {
            uint256[] memory ids = new uint256[](tokenCount);
            string[] memory urls = new string[](tokenCount);

            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
                ids[i] = tokenId;
                urls[i] = tokenURI(tokenId);
            }
            _ids = ids;
            _uri = urls;
        }
    }

    function getTokensWithAttributesOwner(address _owner)
        external
        view
        override
        returns (TokenAttributes[] memory tokenAttributes)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            tokenAttributes = new TokenAttributes[](0);
        } else {
            tokenAttributes = new TokenAttributes[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                uint256 tokenId = tokenOfOwnerByIndex(_owner, i);
                tokenAttributes[i] = allTokenAttributes[tokenId];
            }
        }
    }

    function getTokensOfOwner(address _owner)
        external
        view
        override
        returns (uint256[] memory _ids)
    {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            _ids = new uint256[](0);
        } else {
            uint256[] memory ids = new uint256[](tokenCount);
            for (uint256 i = 0; i < tokenCount; i++) {
                ids[i] = tokenOfOwnerByIndex(_owner, i);
            }
            _ids = ids;
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
