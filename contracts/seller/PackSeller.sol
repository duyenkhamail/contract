pragma solidity ^0.8.0;

import "../libs/KaijuLibrary.sol";
import "../libs/RandomHelper.sol";
import "../libs/RoleDefine.sol";
import "../libs/TypeDefine.sol";
import "../interfaces/IKaijuRouter.sol";
import "../interfaces/INFT.sol";
import "../interfaces/IKaijuFT.sol";
import "../interfaces/IFactory.sol";

import "../nft/KaijuNFT.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract PackSeller is
    Initializable,
    AccessControlUpgradeable,
    IERC1155Receiver,
    IERC721Receiver
{
    using SafeMath for uint256;
    struct Land {
        uint256 TypeId;
        uint256 Id;
    }

    uint256 public startTime;
    address public packAddress;
    address public sellerAddress;
    uint256[] public prices;
    uint256[] public amounts;
    mapping(uint256 => uint256) public soldAmounts;

    IKaijuRouter router;
    IFactory factory;

    bool private locked;

    //Nonce for random
    uint256 private plantNonce;
    uint256 private eggNonce;
    uint256 private avatarNonce;
    uint256 private avatarFrameNonce;
    uint256 private landNonce;

    //Max for item value
    uint256 public maxBasicEggId;
    uint256 public maxAvatarId;
    uint256 public maxAvatarFrameId;
    address[] public addressList;
    mapping(address => bool) public whitelist;
    mapping(address => bool) public claim;

    uint256 private promoPackNonce;
    bool public canClaim;

    address[] public addressTop;
    mapping(address => uint256) public toplist;
    mapping(address => bool) public rewarded;

    bool public canRewardTop;

    mapping(address => uint256[]) public topdaily;
    address[] public addressDaily;
    bool public canRewardDaily;

    event OpenPackComplete(address account, uint256 packId);
    event OpenItem(
        address account,
        uint256 _packId,
        string _type,
        address _contract,
        string _uri
    );
    event BuyPack(address account, uint256 _packId, uint256 _amount);

    function initialize(
        uint256[] memory _prices,
        uint256[] memory _amounts,
        address _packAddress,
        uint256 _startTime,
        address _router
    ) public initializer {
        sellerAddress = msg.sender;
        prices = _prices;
        amounts = _amounts;
        packAddress = _packAddress;
        startTime = _startTime;
        router = IKaijuRouter(_router);
        factory = IFactory(router.getFactory());

        plantNonce = 1;
        eggNonce = 1;
        avatarNonce = 1;
        avatarFrameNonce = 1;
        landNonce = 1;

        //Max for item value
        maxBasicEggId = 4;
        maxAvatarId = 15;
        maxAvatarFrameId = 10;
        locked = false;
        _setupRole(RoleDefine.DEFAULT_ADMIN_ROLE, msg.sender);

        promoPackNonce = 1;
        canClaim = false;
        canRewardDaily = false;
        canRewardTop = false;
    }

    function setCanClaim(bool _canClaim)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        canClaim = _canClaim;
    }

    function setCanRewardTop(bool _canReward)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        canRewardTop = _canReward;
    }

    function setCanRewardDaily(bool _canReward)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        canRewardDaily = _canReward;
    }

    function addTopDaily(address[] memory _topDaily, uint256[][] memory _tops)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        require(_topDaily.length == _tops.length, "PackSeller: INVALID LENGTH");
        for (uint256 i = 0; i < _topDaily.length; i++) {
            topdaily[_topDaily[i]] = _tops[i];
            addressDaily.push(_topDaily[i]);
        }
    }

    function clearTopDaily() external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addressDaily.length; i++) {
            delete topdaily[addressDaily[i]];
        }
        delete addressDaily;
    }

    function getTopDaily(address _account)
        external
        view
        returns (uint256[] memory)
    {
        return topdaily[_account];
    }

    function getTopDailyLength() external view returns (uint256) {
        return addressDaily.length;
    }

    function addWhiteList(address[] memory _whitelist)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            if (whitelist[_whitelist[i]] == false) {
                addressList.push(_whitelist[i]);
                whitelist[_whitelist[i]] = true;
            }
        }
    }

    function clearWhitelist() external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addressList.length; i++) {
            whitelist[addressList[i]] = false;
        }
        delete addressList;
    }

    function getAllWhiteList() external view returns (address[] memory) {
        return addressList;
    }

    function getWhiteListLength() external view returns (uint256) {
        return addressList.length;
    }

    function clearClaimList(address[] memory _list)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            claim[_list[i]] = false;
        }
    }

    function addTopList(address[] memory _toplist, uint256[] memory _tops)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        require(_toplist.length == _tops.length, "PackSeller: INVALID LENGTH");
        for (uint256 i = 0; i < _toplist.length; i++) {
            addressTop.push(_toplist[i]);
            toplist[_toplist[i]] = _tops[i];
        }
    }

    function clearTopList() external onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < addressTop.length; i++) {
            toplist[addressTop[i]] = 0;
        }
        delete addressTop;
    }

    function getAllTopList() external view returns (address[] memory) {
        return addressTop;
    }

    function getTopListLength() external view returns (uint256) {
        return addressList.length;
    }

    function clearRewardList(address[] memory _list)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _list.length; i++) {
            rewarded[_list[i]] = false;
        }
    }

    function rewardDailyTop() external {
        require(canRewardDaily, "PackSeller: CANNOT CLAIM");

        uint256[] memory top = topdaily[msg.sender];
        if (top.length == 0) {
            require(false, "YOU ARE CANNOT CLAIM");
        }
        if (top[0] > 0) {
            for (uint256 i = 0; i < top[0]; i++) {
                randomEgg(0);
            }
        }
        if (top.length > 1) {
            if (top[1] > 0) {
                for (uint256 i = 0; i < top[1]; i++) {
                    randomAvatar(0);
                }
            }
        }
        topdaily[msg.sender] = new uint256[](0);
    }

    function rewardTopReferral() external {
        require(canRewardTop, "PackSeller: CANNOT CLAIM");
        require(toplist[msg.sender] > 0, "YOU ARE NOT IN TOP REFERRAL PROGRAM");
        require(rewarded[msg.sender] == false, "YOU HAVE REWARDED");
        uint256 top = toplist[msg.sender];
        if (top == 1) {
            randomLand(0);
            randomLand(0);
            randomSkill(0);
            randomSkill(0);
            randomEgg(0);
            randomEgg(0);
            randomAvatar(0);
            randomAvatar(0);
        } else if (top == 2 || top == 3) {
            randomLand(0);
            randomSkill(0);
            randomEgg(0);
            randomAvatar(0);
        } else if (top <= 32) {
            randomLand(0);
            randomEgg(0);
            randomAvatar(0);
        } else if (top <= 100) {
            randomSkill(0);
            randomEgg(0);
            randomAvatar(0);
        } else {
            randomAvatar(0);
            uint256 rdValue = RandomHelper.randomId(top, 10);
            rdValue = rdValue.mod(2);
            if (rdValue == 0) {
                randomEgg(0);
            } else {
                randomSkill(0);
            }
        }
        rewarded[msg.sender] = true;
    }

    function claimPromoPack() external {
        require(canClaim, "PackSeller: CANNOT CLAIM");
        require(
            whitelist[msg.sender] == true,
            "PackSeller: YOU ARE NOT IN WHITELIST"
        );
        require(
            claim[msg.sender] == false,
            "PackSeller: YOU ARE ALREADY CLAIMED"
        );
        router.mintFT(msg.sender, "PACK", 1);
        claim[msg.sender] = true;
    }

    function setSellerAddress(address _seller)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        sellerAddress = _seller;
    }

    function withdrawNFT(address _address, uint256[] memory _ids)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        IERC721 nft = IERC721(_address);
        for (uint256 i = 0; i < _ids.length; i++) {
            nft.transferFrom(address(this), msg.sender, _ids[i]);
        }
    }

    function withdrawFT(address _address, uint256[] memory _ids)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        IERC1155 ft = IERC1155(_address);
        address[] memory accounts = new address[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            accounts[i] = address(this);
        }
        uint256[] memory amountsFt = ft.balanceOfBatch(accounts, _ids);
        ft.safeBatchTransferFrom(
            address(this),
            msg.sender,
            _ids,
            amountsFt,
            "0x"
        );
    }

    function setRouterAddress(address _router)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        router = IKaijuRouter(_router);
        factory = IFactory(router.getFactory());
    }

    function setStartTime(uint256 _startTime)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        startTime = _startTime;
    }

    function setPackAddress(address _packAddress)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        packAddress = _packAddress;
    }

    function setAmounts(uint256[] memory _amounts)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        amounts = _amounts;
    }

    function clearSoldAmounts()
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < 6; i++) {
            soldAmounts[i] = 0;
        }
    }

    function setPrices(uint256[] memory _prices)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        prices = _prices;
    }

    function getAmounts() external view returns (uint256[] memory) {
        return amounts;
    }

    function getPrices() external view returns (uint256[] memory) {
        return prices;
    }

    function getPacks()
        external
        view
        returns (
            uint256[] memory _prices,
            uint256[] memory _amounts,
            uint256[] memory _sold_amounts
        )
    {
        uint256[] memory solds = new uint256[](amounts.length);
        _amounts = amounts;
        _prices = prices;
        for (uint256 i = 0; i < amounts.length; i++) {
            solds[i] = soldAmounts[i];
        }
        _sold_amounts = solds;
    }

    modifier lock() {
        require(locked == false, "PackSeller: LOCKING");
        locked = true;
        _;
        locked = false;
    }

    function openPack(uint256 _packId) external {
        IERC1155 pack = IERC1155(packAddress);

        pack.safeTransferFrom(
            msg.sender,
            KaijuLibrary.getBurnAddress(),
            _packId,
            1,
            "0x"
        );
        if (_packId == 1) {
            randomPromoPack(_packId);
        }
        if (_packId == 2) {
            transferTokenCard(_packId, 2);
            randomAvatar(_packId);
            randomEgg(_packId);
        }
        if (_packId == 3) {
            transferTokenCard(_packId, 2);
            randomSkill(_packId);
            randomAvatar(_packId);
            randomEgg(_packId);
        }
        if (_packId == 4) {
            transferTokenCard(_packId, 2);
            randomAvatar(_packId);

            randomEgg(_packId);
            randomEgg(_packId);
            randomSkill(_packId);
            randomSkill(_packId);
        }
        if (_packId == 5) {
            transferTokenCard(_packId, 2);
            randomAvatar(_packId);
            randomEgg(_packId);
            randomSkill(_packId);
            randomLand(_packId);
        }
        emit OpenPackComplete(msg.sender, _packId);
    }

    function randomPromoPack(uint256 _packId) internal {
        uint256 _randomNumber = RandomHelper.randomNumber();
        uint256 _rate = RandomHelper.randomPromoRate(
            promoPackNonce,
            _randomNumber
        );
        if (_rate == 0) {
            randomAvatar(_packId);
        }
        if (_rate == 1) {
            transferTokenCard(_packId, 1);
        }
        if (_rate == 2) {
            randomEgg(_packId);
        }
        if (_rate == 3) {
            randomSkill(_packId);
        }
        if (_rate == 4) {
            randomLand(_packId);
        }
        promoPackNonce = promoPackNonce.add(1);
    }

    function randomSkill(uint256 _packId) internal {
        address nftAddress = factory.getNFTContract(TypeDefine.SKILL);

        if (nftAddress != address(0)) {
            KaijuNFT nft = KaijuNFT(nftAddress);
            uint256 _randomNumber = RandomHelper.randomNumber();
            uint256 nonce = nft.totalSupply() + 1;
            uint256 _rarity = RandomHelper.randomRarity(nonce, _randomNumber);
            _randomNumber = nonce.mod(4);
            uint256 typeId = _randomNumber.mul(10).add(
                _rarity.mul(2).add(nonce.mod(2).add(1))
            );
            (uint256 _tokenId, ) = router.mintNFT(
                msg.sender,
                TypeDefine.SKILL,
                typeId
            );
            emit OpenItem(
                msg.sender,
                _packId,
                TypeDefine.SKILL,
                nftAddress,
                nft.tokenURI(_tokenId)
            );
        }
    }

    function transferTokenCard(uint256 _packId, uint256 _cardId)
        internal
        returns (address _contract, uint256 _id)
    {
        router.mintFT(msg.sender, TypeDefine.TOKEN_CARD, _cardId);
        _contract = router.getTokenCardAddress();
        IKaijuFT ft = IKaijuFT(_contract);
        _id = _cardId;
        emit OpenItem(
            msg.sender,
            _packId,
            TypeDefine.TOKEN_CARD,
            _contract,
            ft.tokenURI(_cardId)
        );
    }

    function randomLand(uint256 _packId)
        internal
        returns (address _contract, uint256 _nftId)
    {
        address nftAddress = factory.getNFTContract(TypeDefine.LAND);

        if (nftAddress != address(0)) {
            KaijuNFT nft = KaijuNFT(nftAddress);
            uint256 _randomNumber = RandomHelper.randomNumber();
            uint256 nonce = nft.totalSupply() + 1;
            uint256 _rarity = RandomHelper.randomRarity(nonce, _randomNumber);
            _randomNumber = nonce.mod(4);
            uint256 typeId = _randomNumber;
            (uint256 _tokenId, ) = router.mintNFT(
                msg.sender,
                TypeDefine.LAND,
                typeId
            );
            emit OpenItem(
                msg.sender,
                _packId,
                TypeDefine.LAND,
                nftAddress,
                nft.tokenURI(_tokenId)
            );
        }
    }

    function randomAvatar(uint256 _packId)
        internal
        returns (address _contract, uint256 _id)
    {
        uint256 randomId = RandomHelper.randomId(avatarNonce, maxAvatarId);
        router.mintFT(msg.sender, TypeDefine.AVATAR, randomId);
        _contract = router.getAvatarAddress();
        _id = randomId;
        avatarNonce = avatarNonce.add(1);
        IKaijuFT ft = IKaijuFT(_contract);
        emit OpenItem(
            msg.sender,
            _packId,
            TypeDefine.AVATAR,
            _contract,
            ft.tokenURI(_id)
        );
    }

    function randomEgg(uint256 _packId)
        internal
        returns (address _contract, uint256 _id)
    {
        uint256 randomId = RandomHelper.randomId(eggNonce, maxBasicEggId);
        router.mintFT(msg.sender, TypeDefine.EGG, randomId);
        _contract = router.getEggAddress();
        _id = randomId;

        eggNonce = eggNonce.add(1);
        IKaijuFT ft = IKaijuFT(_contract);
        emit OpenItem(
            msg.sender,
            _packId,
            TypeDefine.EGG,
            _contract,
            ft.tokenURI(_id)
        );
    }

    function buyPack(uint256 _packId, uint256 _amount)
        external
        payable
        lock
        returns (bool)
    {
        if(_packId<5){
            require(_amount<=5, "PackSeller: MAX AMOUNT IS 5");
        }
        else{
             require(_amount==1, "PackSeller: MAX AMOUNT IS 1");
        }
        require(
            block.timestamp >= startTime,
            "PackSeller: SALE DOES NOT START"
        );
        require(prices[_packId] > 0, "INVALID PACK ID");
        require(
            soldAmounts[_packId].add(_amount) <= amounts[_packId],
            "PackSeller: INVALID AMOUNT"
        );

        IERC1155 pack = IERC1155(packAddress);
        require(
            pack.balanceOf(address(this), _packId) >= _amount,
            "PackSeller: REMAIN AMOUNT IS NOT ENOUGH!"
        );
        uint256 price = prices[_packId];
        uint256 amountIn = msg.value;
        uint256 totalAmount = price.mul(_amount);
        require(amountIn >= totalAmount, "PackSeller: INSUFFICIENT BNB AMOUNT");
        if (amountIn > totalAmount) {
            uint256 refundAmount = amountIn.sub(totalAmount);
            KaijuLibrary.safeTransferBNB(msg.sender, refundAmount);
        }
        KaijuLibrary.safeTransferBNB(sellerAddress, totalAmount);
        pack.safeTransferFrom(
            address(this),
            msg.sender,
            _packId,
            _amount,
            "0x"
        );

        soldAmounts[_packId] = soldAmounts[_packId].add(_amount);
        emit BuyPack(msg.sender, _packId, _amount);
        return true;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, IERC165)
        returns (bool)
    {
        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
