pragma solidity ^0.8.0;
import "../libs/OnlyRouter.sol";
import "./KaijuFT.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Eggs is KaijuFT {
    using SafeMath for uint256;
    mapping(uint256 => address) firstOwners;
    uint256 public mixingTableSize;

    //Define events
    event BuyEggs(uint256 _eggId, uint256 _amount);
    event MergeEggs(uint256 _egg1, uint256 _egg2);
    event OpenEgg(uint256 _eggId);
    function initializeEgg(string memory _uri) public initializer {
        
        initFT(_uri, "EGG");
    }

    // function setSwapAndLiquidityAddress(address _swap) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
    //     swapAndLiquidity = ISwapAndLiquidity(_swap);
    // }

    // function setMainToken(address _mainToken) external  onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
    //     mainToken = IERC20(_mainToken);
    // }

    // function getMainTokenAddress() external view returns (address) {
    //     return address(mainToken);
    // }
    // function recoverKaiju(uint256 amount) external  onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE){
    //     mainToken.transfer(msg.sender, amount);
    // }
    function buyEggs(
        address account,
        uint256 _eggId,
        uint256 _amount
    ) external onlyRole(RoleDefine.PLATFORM_ROUTER) returns (uint256 _result) {
        _mint(account, _eggId, _amount, "0x");
        _result = 1;
       
        emit BuyEggs(_eggId, _amount);
    }

    function mergeEggs(
        address account,
        uint256 _egg1,
        uint256 _egg2,
        uint256 _combinedEgg
    ) external onlyRole(RoleDefine.PLATFORM_ROUTER) {
        _burn(account, _egg1, 1);
        _burn(account, _egg2, 1);

        if (_combinedEgg > 0) {
            _mint(account, _combinedEgg, 1, "0x");
            if (firstOwners[_combinedEgg] == address(0)) {
                firstOwners[_combinedEgg] = account;
            }
        }

        emit MergeEggs(_egg1, _egg2);
    }
    function burnEgg(address account, uint256 _eggId) external  onlyRole(RoleDefine.PLATFORM_ROUTER) {
        _burn(account, _eggId, 1);
    }
}
