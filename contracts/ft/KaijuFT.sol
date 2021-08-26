pragma solidity ^0.8.0;
import "../libs/OnlyRouter.sol";
import "../interfaces/IKaijuFT.sol";
import "../libs/StringsHelper.sol";
// import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../libs/RoleDefine.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract KaijuFT is
    Initializable,
    ERC1155Upgradeable,
    AccessControlUpgradeable,
    IKaijuFT
{
    string public currentUri;
    using StringsHelper for uint256;
    using StringsHelper for address;
    string public ftType;
    uint256 maxId;

    function initialize(string memory _uri, string memory _type)
        public
        initializer
    {
        initFT(_uri, _type);
        maxId = 0;
    }

    function initFT(string memory _uri, string memory _type) internal {
        ftType = _type;
        __ERC1155_init(_uri);
        _setupRole(RoleDefine.DEFAULT_ADMIN_ROLE, msg.sender);
    }
    function grantRouter(address _router) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        grantRole(RoleDefine.PLATFORM_ROUTER, _router);
    }
    function getMaxId() public view override returns (uint256) {
        return maxId;
    }

    function getFtType() public view returns (string memory) {
        return ftType;
    }

    function setUri(string memory newuri)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        currentUri = newuri;
    }

    function _setURI(string memory newuri) internal override {
        currentUri = newuri;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        string memory baseURI = currentUri;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, ftType, "/", tokenId.toString())
                )
                : "";
    }

    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory baseURI = currentUri;
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, ftType, "/", tokenId.toString())
                )
                : "";
    }

    function mintByOwner(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external override onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        if (_id > maxId) {
            maxId = _id;
        }
        _mint(_to, _id, _amount, "0x");
    }

    function mintByRouter(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external override onlyRole(RoleDefine.PLATFORM_ROUTER) {
        if (_id > maxId) {
            maxId = _id;
        }
        _mint(_to, _id, _amount, "0x");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
