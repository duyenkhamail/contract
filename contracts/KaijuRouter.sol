pragma solidity ^0.8.0;

import "./ft/Eggs.sol";
import "./nft/KaijuNFT.sol";
import "./interfaces/IDatabase.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/INFT.sol";
import "./interfaces/IKaijuFT.sol";
import "./interfaces/IKaijuRouter.sol";
import "./libs/KaijuLibrary.sol";
import "./libs/TypeDefine.sol";
import "./libs/RoleDefine.sol";
import "./libs/StringsHelper.sol";
import "./libs/RandomHelper.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract KaijuRouter is Initializable, AccessControlUpgradeable, IKaijuRouter {
    using SafeMath for uint256;
    using StringsHelper for string;
    
    IERC20 private mainToken;

    uint256 public basicEggPrice;
    uint256 public maxBasicEgg;
    mapping(uint256 => bool) basicEggs;

    address public stakingContractAddress;
    uint256 public _liquidityFee;
    IDatabase public kaijuDatabase;
    bool public gameStarted;
    IFactory public factory;
    string public baseNftUri;

    address public packSeller;

    event BuyEgg(address account, uint256 eggId, uint256 amount);
    event MergeEggs(
        address account,
        uint256 egg1,
        uint256 egg2,
        uint256 combinedEgg
    );

    event OpenMonsterPack(
        address account,
        uint256 monsterTypeId,
        uint256 nftId,
        uint256 rarity
    );
    event MintNFT(
        address _account,
        string _type,
        uint256 _typeId,
        uint256 _nftId,
        string _uri
    );

    function initialize(address _mainToken, address _database)
        public
        initializer
    {
        mainToken = IERC20(_mainToken);
        kaijuDatabase = IDatabase(_database);
       
        basicEggs[1] = true;
        basicEggs[2] = true;
        basicEggs[3] = true;
        basicEggs[4] = true;
        baseNftUri = "https://data.kaijuworlds.io/nft/";
        _setupRole(RoleDefine.DEFAULT_ADMIN_ROLE, msg.sender);
        basicEggPrice = 330 * 10**18;
        maxBasicEgg = 4;
        _liquidityFee = 50;
        gameStarted = false;
    }
    function recoverKaiju(uint256 amount) external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE){
        mainToken.transfer(msg.sender, amount);
    }
    function setGameStarted(bool _started)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        gameStarted = _started;
    }

    function setBaseNftUri(string memory newuri)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        baseNftUri = newuri;
    }

    function setSellerAddress(address _seller)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        packSeller = _seller;
    }

    function getEggAddress() external view override returns (address) {
        return factory.getFTContract(TypeDefine.EGG);
    }

    function getAvatarAddress() external view override returns (address) {
        return factory.getFTContract(TypeDefine.AVATAR);
    }


    function getTokenCardAddress() external view override returns (address) {
        return factory.getFTContract(TypeDefine.TOKEN_CARD);
    }

    function setBasicEggs(uint256[] memory ids, bool[] memory values)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < ids.length; i++) {
            basicEggs[ids[i]] = values[i];
        }
    }


    function mintFT(
        address _to,
        string memory _type,
        uint256 _id
    ) external override returns (bool) {
        require(msg.sender == packSeller, "KaijuRouter: CALLER IS NOT SELLER");
        IKaijuFT ft = IKaijuFT(factory.getFTContract(_type));
        ft.mintByRouter(_to, _id, 1);
        return true;
    }



    function mintNFT(
        address _to,
        string memory _type,
        uint256 _typeId
    ) external override returns (uint256 nftId, uint256 _rarity) {
        require(msg.sender == packSeller, "KaijuRouter: CALLER IS NOT SELLER");
        address nftAddress = factory.getNFTContract(_type);

        if (nftAddress != address(0)) {
            KaijuNFT nft = KaijuNFT(nftAddress);
            if (_type.compare(TypeDefine.SKILL)) {
                uint256 modResult = _typeId.sub(1).mod(10);
                _rarity = modResult.sub(modResult.mod(2)).div(2);
            } else {
                uint256 _randomNumber = RandomHelper.randomNumber();
                uint256 nonce = nft.getTotalNFT(_typeId) + 1;
                _rarity = RandomHelper.randomRarity(nonce, _randomNumber);
            }
            (bool openResult, string memory message, uint256 _nftId) = nft
                .mintNFT(_to, _typeId, _rarity, 0);
            nftId = _nftId;
            emit MintNFT(_to, _type, _typeId, _nftId, nft.tokenURI(_nftId));
        }
    }

    function mintNFTByOwner(
        address _to,
        string memory _type,
        uint256 _typeId
    )
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
        returns (uint256 nftId, uint256 _rarity)
    {
        address nftAddress = factory.getNFTContract(_type);

        if (nftAddress != address(0)) {
            KaijuNFT nft = KaijuNFT(nftAddress);
            if (_type.compare(TypeDefine.SKILL)) {
                uint256 modResult = _typeId.sub(1).mod(10);
                _rarity = modResult.sub(modResult.mod(2)).div(2);
            } else {
                uint256 _randomNumber = RandomHelper.randomNumber();
                uint256 nonce = nft.getTotalNFT(_typeId) + 1;
                _rarity = RandomHelper.randomRarity(nonce, _randomNumber);
            }
            (bool openResult, string memory message, uint256 _nftId) = nft
                .mintNFT(_to, _typeId, _rarity, 0);
            nftId = _nftId;
            emit MintNFT(_to, _type, _typeId, _nftId, nft.tokenURI(_nftId));
        }
    }

    function setFactory(address _factory)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        factory = IFactory(_factory);
    }

    function getFactory() external view override returns (address) {
        return address(factory);
    }

    function setKaijuDatabase(address _database)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        kaijuDatabase = IDatabase(_database);
    }

    function setStakingContractAddress(address _stakingAddress)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        stakingContractAddress = _stakingAddress;
    }

    function setMainToken(address _mainToken)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        mainToken = IERC20(_mainToken);
    }

    function getMainTokenAddress() external view returns (address) {
        return address(mainToken);
    }

    function setLiquidityFee(uint256 _fee)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        _liquidityFee = _fee;
    }

    function setBasicEggPrice(uint256 _price)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        basicEggPrice = _price;
    }

    function buyEgg(uint256 _eggId, uint256 _amount)
        external
        returns (bool success)
    {
        require(gameStarted, "KaijuRouter: GAME DOES NOT START");
        require(
            factory.getFTContract(TypeDefine.EGG) != address(0),
            "KaijuRouter: INVALID EGG CONTRACT"
        );

        Eggs contractEggs = Eggs(factory.getFTContract(TypeDefine.EGG));
        require(basicEggs[_eggId] == true, "INVALID EGG ID");

        uint256 totalPrice = _amount.mul(basicEggPrice);

        mainToken.transferFrom(msg.sender, address(this), totalPrice);
      
        contractEggs.buyEggs(msg.sender, _eggId, _amount);
        success = true;
        emit BuyEgg(msg.sender, _eggId, _amount);
    }

    function openEgg(uint256 _eggId) external {
        Eggs contractEggs = Eggs(factory.getFTContract(TypeDefine.EGG));
        contractEggs.burnEgg(msg.sender, _eggId);
        KaijuNFT monsterContract = KaijuNFT(
            factory.getNFTContract(TypeDefine.MONSTER)
        );

        uint256 nonce = monsterContract.getTotalNFT(_eggId) + 1;
        uint256 _randomNumber = RandomHelper.randomNumber();
        uint256 _rarity = RandomHelper.randomRarity(nonce, _randomNumber);
        (
            bool openResult,
            string memory message,
            uint256 nftId
        ) = monsterContract.mintNFT(msg.sender, _eggId, _rarity, 0);
        emit MintNFT(
            msg.sender,
            TypeDefine.MONSTER,
            _eggId,
            nftId,
            monsterContract.tokenURI(nftId)
        );
    }

    function fusionEggs(uint256 _egg1, uint256 _egg2)
        external
        returns (uint256 combinedEgg)
    {
        require(gameStarted, "KaijuRouter: GAME DOES NOT START");
        combinedEgg = kaijuDatabase.mergeEggs(_egg1, _egg2);
        require(combinedEgg > 0, "KaijuRouter: FUSING WRONG");
        Eggs contractEggs = Eggs(factory.getFTContract(TypeDefine.EGG));
        contractEggs.mergeEggs(msg.sender, _egg1, _egg2, combinedEgg);

        emit MergeEggs(msg.sender, _egg1, _egg2, combinedEgg);
    }

    function inventoryNFTWithUriOf(address _account, string memory _type)
        external
        view
        returns (uint256[] memory ids, string[] memory uri)
    {
        address nftContractAddress = factory.getNFTContract(_type);
        INFT nft = INFT(nftContractAddress);
        (ids, uri) = nft.getTokensWithUriOfOwner(_account);
    }

    function inventoryNFTOf(address _account, string memory _type)
        external
        view
        returns (INFT.TokenAttributes[] memory _inventory)
    {
        address nftContractAddress = factory.getNFTContract(_type);
        INFT nft = INFT(nftContractAddress);
        _inventory = nft.getTokensWithAttributesOwner(_account);
    }

    function inventoryFTOf(
        address _account,
        string memory _type,
        uint256 _maxId
    ) external view returns (InventoryFT memory _inventory) {
        address ftContract = factory.getFTContract(_type);
        require(ftContract != address(0), "KaijuRouter: INVALID FT TYPE");
        ERC1155 ercContract = ERC1155(ftContract);

        uint256[] memory ids = new uint256[](_maxId);
        address[] memory accounts = new address[](_maxId);
        for (uint256 i = 1; i <= _maxId; i++) {
            ids[i.sub(1)] = i;
            accounts[i.sub(1)] = _account;
        }
        uint256[] memory balances = ercContract.balanceOfBatch(accounts, ids);
        _inventory = InventoryFT(ids, balances);
    }
}
