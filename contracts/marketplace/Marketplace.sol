pragma solidity ^0.8.0;

import "../interfaces/INFT.sol";
import "../interfaces/IKaijuFT.sol";
import "../interfaces/IKaijuRouter.sol";
import "../interfaces/IFactory.sol";
import "../libs/KaijuLibrary.sol";
import "../libs/StringsHelper.sol";
import "../libs/RoleDefine.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract MarketPlace is
    Initializable,
    AccessControlUpgradeable,
    IERC1155Receiver
{
    using StringsHelper for string;
    using SafeMath for uint256;

    struct PaymentMethods {
        string BNB;
        string Kaiju;
    }
    struct SaleStatus {
        string ACTIVE;
        string CANCELED;
        string SOLD;
    }
    struct SaleItem {
        uint256 SaleIndex;
        string Type;
        uint256 TypeId;
        uint256 TokenId;
        uint256 AtTime;
        uint256 Price;
        string PaymentMethod;
        address Owner;
        string Status;
        bool IsAuction;
        bool IsNFT;
        address Buyer;
        uint256 CompletedTime;
    }

    bool private locked;
    uint256 public marketFeeBNBPercent;
    uint256 public marketFeeKaijuPercent;
    address[] public feeReceivers;

    modifier lock() {
        require(locked == false, "Kaiju Marketplace: LOCKING");
        locked = true;
        _;
        locked = false;
    }
    SaleStatus public saleStatus;
    PaymentMethods public paymentMethods;
    IFactory public factory;
    IKaijuRouter public router;
    IERC20 public kaijuToken;
    SaleItem[] public salesNFT;
    SaleItem[] public salesFT;
    mapping(address => uint256[]) public ownerSalesNFT;
    mapping(address => uint256[]) public ownerSalesFT;

    event SaleEvent(SaleItem item);
    event SellEvent(SaleItem item);
    event SoldEvent(SaleItem item);
    event CancelEvent(SaleItem item);
    event UpdatePrice(SaleItem item, uint256 _oldPrice);

    function initialize(address _router) public initializer {
        router = IKaijuRouter(_router);
        factory = IFactory(router.getFactory());
        saleStatus = SaleStatus("ACTIVE", "CANCELED", "SOLD");
        paymentMethods = PaymentMethods("BNB", "Kaiju");
        locked = false;
        marketFeeBNBPercent = 70;
        marketFeeKaijuPercent = 70;
        _setupRole(RoleDefine.DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // function getSaleLength(bool isNFT) external view returns(uint256){
    //     if(isNFT){
    //         return salesNFT.length;
    //     }
    //     return salesFT.length;
    // }
    function setFeeReceivers(address[] memory _addresses)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        feeReceivers = _addresses;
    }

    function sendBNBFee() internal {
        uint256 balance = address(this).balance;
        uint256 perAccount = balance.div(feeReceivers.length);
        if (perAccount.mul(feeReceivers.length) > balance) {
            perAccount = perAccount.sub(1);
        }
        for (uint256 i = 0; i < feeReceivers.length; i++) {
            KaijuLibrary.safeTransferBNB(feeReceivers[i], perAccount);
        }
    }

    function sendKaijuFee() internal {
        uint256 balance = kaijuToken.balanceOf(address(this));
        uint256 perAccount = balance.div(feeReceivers.length);
        if (perAccount.mul(feeReceivers.length) > balance) {
            perAccount = perAccount.sub(1);
        }
        for (uint256 i = 0; i < feeReceivers.length; i++) {
            kaijuToken.transfer(feeReceivers[i], perAccount);
        }
    }

    function getSalesLength(bool isNFT) external view returns (uint256) {
        if (isNFT) {
            return salesNFT.length;
        } else {
            return salesFT.length;
        }
    }

    function updatePrice(
        uint256 _saleId,
        uint256 _price,
        bool isNFT
    ) external {
        SaleItem memory item;
        uint256 _oldPrice;
        if (isNFT) {
            require(
                _saleId < salesNFT.length,
                "Kaiju Marketplace: INVALID SALE ID"
            );

            item = salesNFT[_saleId];
            require(
                item.Owner == msg.sender,
                "Kaiju Marketplace: CALLER IS NOT SALE OWNER"
            );
            require(
                item.Status.compare(saleStatus.ACTIVE),
                "Kaiju Marketplace: SALE IS NOT ACTIVE"
            );

            _oldPrice = item.Price;
            item.Price = _price;
            salesNFT[_saleId].Price = _price;
        } else {
            require(
                _saleId < salesFT.length,
                "Kaiju Marketplace: INVALID SALE ID"
            );

            item = salesFT[_saleId];
            require(
                item.Owner == msg.sender,
                "Kaiju Marketplace: CALLER IS NOT SALE OWNER"
            );
            require(
                item.Status.compare(saleStatus.ACTIVE),
                "Kaiju Marketplace: SALE IS NOT ACTIVE"
            );
            _oldPrice = item.Price;
            item.Price = _price;
            salesFT[_saleId].Price = _price;
        }

        emit UpdatePrice(item, _oldPrice);
    }

    function getSalesIdOf(address _owner, bool isNFT)
        external
        view
        returns (uint256[] memory)
    {
        if (isNFT) {
            return ownerSalesNFT[_owner];
        } else {
            return ownerSalesFT[_owner];
        }
    }

    // function getSalesOf(address _owner, bool isNFT)
    //     external
    //     view
    //     returns (SaleItem[] memory)
    // {
    //     if (isNFT) {
    //         uint256[] memory ids = ownerSalesNFT[_owner];
    //         SaleItem[] memory results = new SaleItem[](ids.length);
    //         uint256 index = 0;
    //         for (uint256 i = 0; i < ids.length; i++) {
    //             results[index] = salesNFT[ids[i]];
    //             index = index.add(1);
    //         }
    //         return results;
    //     } else {
    //         uint256[] memory ids = ownerSalesFT[_owner];
    //         SaleItem[] memory results = new SaleItem[](ids.length);
    //         uint256 index = 0;
    //         for (uint256 i = 0; i < ids.length; i++) {
    //             results[index] = salesFT[ids[i]];
    //             index = index.add(1);
    //         }
    //         return results;
    //     }
    // }

    // function getSalesOfPage(
    //     address _owner,
    //     uint256 _pageNum,
    //     uint256 _pageSize,
    //     bool isNFT
    // ) external view returns (SaleItem[] memory) {
    //     require(_pageNum > 0, "Kaiju Marketplace: INVALID PAGE NUM");
    //     require(_pageSize > 0, "Kaiju Marketplace: INVALID PAGE SIZE");
    //     SaleItem[] memory results;
    //     if (isNFT) {
    //         uint256[] memory ids = ownerSalesNFT[_owner];
    //         uint256 startIndex = _pageNum.sub(1).mul(_pageSize);
    //         uint256 endIndex = startIndex.add(_pageSize);
    //         if (endIndex > ids.length) {
    //             endIndex = ids.length;
    //         }
    //         if (endIndex < startIndex) {
    //             endIndex = startIndex;
    //         }

    //         uint256 index = 0;
    //         results = new SaleItem[](endIndex.sub(startIndex));
    //         for (uint256 i = startIndex; i < endIndex; i++) {
    //             results[index] = salesNFT[ids[i]];
    //             index = index.add(1);
    //         }
    //     } else {
    //         uint256[] memory ids = ownerSalesFT[_owner];
    //         uint256 startIndex = _pageNum.sub(1).mul(_pageSize);
    //         uint256 endIndex = startIndex.add(_pageSize);
    //         if (endIndex > ids.length) {
    //             endIndex = ids.length;
    //         }
    //         if (endIndex < startIndex) {
    //             endIndex = startIndex;
    //         }

    //         uint256 index = 0;
    //         results = new SaleItem[](endIndex.sub(startIndex));
    //         for (uint256 i = startIndex; i < endIndex; i++) {
    //             results[index] = salesFT[ids[i]];
    //             index = index.add(1);
    //         }
    //     }

    //     return results;
    // }

    function setKaijuToken(address _token)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        kaijuToken = IERC20(_token);
    }

    function setMarketFee(uint256 _bnbFee, uint256 _kaijuFee)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        marketFeeBNBPercent = _bnbFee;
        marketFeeKaijuPercent = _kaijuFee;
    }

    function setRouter(address _router)
        external
        onlyRole(RoleDefine.DEFAULT_ADMIN_ROLE)
    {
        router = IKaijuRouter(_router);
        factory = IFactory(router.getFactory());
    }

    function saleNFT(
        string memory _type,
        uint256 _typeId,
        uint256 _nftId,
        uint256 _price,
        string memory _paymentMethod
    ) external lock {
        require(
            _paymentMethod.compare(paymentMethods.BNB) ||
                _paymentMethod.compare(paymentMethods.Kaiju),
            "Kaiju MarketPlace: INVALID PAYMENT METHOD"
        );
        KaijuLibrary.safeTransferNFT(
            factory,
            _type,
            _nftId,
            msg.sender,
            address(this)
        );
        SaleItem memory saleNft = SaleItem(
            salesNFT.length,
            _type,
            _typeId,
            _nftId,
            block.timestamp,
            _price,
            _paymentMethod,
            msg.sender,
            saleStatus.ACTIVE,
            false,
            true,
            address(0),
            0
        );
        salesNFT.push(saleNft);
        ownerSalesNFT[msg.sender].push(saleNft.SaleIndex);
        emit SaleEvent(saleNft);
    }

    function saleFT(
        string memory _type,
        uint256 _ftId,
        uint256 _price,
        string memory _paymentMethod
    ) external lock {
        require(
            _paymentMethod.compare(paymentMethods.BNB) ||
                _paymentMethod.compare(paymentMethods.Kaiju),
            "Kaiju MarketPlace: INVALID PAYMENT METHOD"
        );

        KaijuLibrary.safeTransferFT(
            factory,
            _type,
            _ftId,
            msg.sender,
            address(this),
            1
        );

        SaleItem memory saleFt = SaleItem(
            salesFT.length,
            _type,
            0,
            _ftId,
            block.timestamp,
            _price,
            _paymentMethod,
            msg.sender,
            saleStatus.ACTIVE,
            false,
            false,
            address(0),
            0
        );
        salesFT.push(saleFt);

        ownerSalesFT[msg.sender].push(saleFt.SaleIndex);
        emit SaleEvent(saleFt);
    }

    function cancelSale(uint256 saleId, bool isNFT) external {
        SaleItem memory item;
        if (isNFT) {
            require(
                saleId < salesNFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesNFT[saleId];

            KaijuLibrary.safeTransferNFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                item.Owner
            );
        } else {
            require(
                saleId < salesFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesFT[saleId];

            KaijuLibrary.safeTransferFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                item.Owner,
                1
            );
        }

        require(
            item.Status.compare(saleStatus.ACTIVE),
            "Kaiju Marketplace: SALE IS NOT ACTIVE"
        );
        require(
            item.Owner == msg.sender,
            "Kaiju Marketplace: ONLY CALL FROM OWNER NFT"
        );

        item.Status = saleStatus.CANCELED;
        item.CompletedTime = block.timestamp;
        if (isNFT) {
            salesNFT[saleId] = item;
        } else {
            salesFT[saleId] = item;
        }
        emit CancelEvent(item);
    }

    function paymentBNB(uint256 itemPrice, address itemOwner) internal {
        uint256 returnValue = msg.value.sub(itemPrice);
        if (returnValue > 0) {
            KaijuLibrary.safeTransferBNB(msg.sender, returnValue);
        }
        uint256 transferAmount = itemPrice.sub(
            itemPrice.mul(marketFeeBNBPercent).div(1000)
        );
        KaijuLibrary.safeTransferBNB(itemOwner, transferAmount);
        sendBNBFee();
    }

    function paymentKaiju(uint256 itemPrice, address itemOwner) internal {
        kaijuToken.transferFrom(msg.sender, address(this), itemPrice);
        uint256 transferAmount = itemPrice.sub(
            itemPrice.mul(marketFeeKaijuPercent).div(1000)
        );
        kaijuToken.transfer(itemOwner, transferAmount);

        sendKaijuFee();
    }

    function purchaseSaleByBNB(
        uint256 saleId,
        bool isNFT,
        uint256 price
    ) external payable {
        SaleItem memory item;
        if (isNFT) {
            require(
                saleId < salesNFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesNFT[saleId];
        } else {
            require(
                saleId < salesFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesFT[saleId];
        }

        require(!item.IsAuction, "Kaiju Marketplace: THIS SALE IS AUCTION!");
        require(
            item.PaymentMethod.compare(paymentMethods.BNB),
            "Kaiju Marketplace: PAYMENT METHOD IS NOT IN BNB"
        );
        require(
            item.Status.compare(saleStatus.ACTIVE),
            "Kaiju Marketplace: SALE IS NOT ACTIVE"
        );
        require(
            price == item.Price,
            "Kaiju Marketplace: THE PRICE WAS UPDATED"
        );
        require(msg.value >= item.Price, "Kaiju Marketplace: INSUFFICIENT BNB");
        
        paymentBNB(item.Price, item.Owner);
        item.Status = saleStatus.SOLD;
        item.Buyer = msg.sender;
        item.CompletedTime = block.timestamp;
        if (isNFT) {
            KaijuLibrary.safeTransferNFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                msg.sender
            );

            salesNFT[saleId] = item;
        } else {
            KaijuLibrary.safeTransferFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                msg.sender,
                1
            );

            salesFT[saleId] = item;
        }
        emit SoldEvent(item);
    }

    function purchaseSaleByKaiju(uint256 saleId, bool isNFT, uint256 price) external {
        SaleItem memory item;
        if (isNFT) {
            require(
                saleId < salesNFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesNFT[saleId];
        } else {
            require(
                saleId < salesFT.length,
                "Kaiju Marketplace: SALE ID INVALID"
            );
            item = salesFT[saleId];
        }

        require(!item.IsAuction, "Kaiju Marketplace: THIS SALE IS AUCTION!");
        require(
            item.PaymentMethod.compare(paymentMethods.Kaiju),
            "Kaiju Marketplace: PAYMENT METHOD IS NOT IN KAIJU"
        );
        require(
            item.Status.compare(saleStatus.ACTIVE),
            "Kaiju Marketplace: SALE IS NOT ACTIVE"
        );

        require(
            price == item.Price,
            "Kaiju Marketplace: THE PRICE WAS UPDATED"
        );
        paymentKaiju(item.Price, item.Owner);
        item.Status = saleStatus.SOLD;
        item.Buyer = msg.sender;
        item.CompletedTime = block.timestamp;
        if (isNFT) {
            KaijuLibrary.safeTransferNFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                msg.sender
            );

            salesNFT[saleId] = item;
        } else {
            KaijuLibrary.safeTransferFT(
                factory,
                item.Type,
                item.TokenId,
                address(this),
                msg.sender,
                1
            );
            salesFT[saleId] = item;
        }

        emit SoldEvent(item);
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
}
