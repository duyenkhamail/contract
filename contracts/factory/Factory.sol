import "../interfaces/IFactory.sol";
import "../interfaces/INFT.sol";
import "../libs/KaijuLibrary.sol";
import "../libs/RoleDefine.sol";
import "../nft/KaijuNFT.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
contract Factory is Initializable, AccessControlUpgradeable, IFactory {
    address public routerAddress;
    mapping(string =>  address) public nftContracts;
    event SetContract(string _type, address _contract);
    mapping(string => address) ftContracts;

    function initialize(address _router) public initializer{

        routerAddress = _router;
        _setupRole(RoleDefine.DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(RoleDefine.PLATFORM_ROUTER, _router);
    }
   

    function setFTContract(string memory _type, address _contract)
        external
        
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        ftContracts[_type] = _contract;
    }

    function getFTContract(string memory _type)
        external
        view
        override
        returns (address)
    {
        return ftContracts[_type];
    }

    function setRouterAddress(address _router) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        routerAddress = _router;
    }

  
    function setNFTContract(
        string memory _type,
        address _address
    ) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        nftContracts[_type] = _address;
        emit SetContract(_type, _address);
    }

  

    function getNFTContract(string memory _type)
        external
        view
        override
        returns (address)
    {
        return nftContracts[_type];
    }


}
