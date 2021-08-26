interface IKaijuRouter {
     struct Inventory {
        uint256 IdInType;
        address ContractAddress;
        uint256[] Id;
        uint256[] Rarity;
        uint256[] Quality;
    }
    struct InventoryFT {
        uint256[] Ids;
        uint256[] Balances;
    }
    function mintNFT(
        address _to,
        string memory _type,
        uint256 _idInType
    ) external returns (uint256 nftId, uint256 rarity);

    function getFactory() external returns (address);
    function getEggAddress() external returns (address);
    function getAvatarAddress() external returns (address);
    function getTokenCardAddress() external returns (address);

    function mintFT(address _to,string memory _type, uint256 _id) external returns (bool);
    // function mintBasicEgg(address _to, uint256 _id) external returns (bool);
    // function mintAvatar(address _to, uint256 _id) external returns (bool);
    // function mintAvatarFrame(address _to, uint256 _id) external returns (bool);
    // function mintTokenCard(address _to, uint256 _id) external returns (bool);

    //  function balancesNFTOf(address _account, string memory _type)
    //     external
    //     view
    //     returns (
    //         uint256[] memory ids,
    //         uint256 totalContract,
    //         uint256[] memory balanceIds
    //     );

    // function inventoryNFTAttributesOf(address _account, string memory _type)
    //     external
    //     view
    //     returns (Inventory[] memory _inventory);

    // function inventoryNFTAttributesTypeId(
    //     address _account,
    //     string memory _type,
    //     uint256 _typeId
    // ) external view returns (Inventory memory _inventory);

    // function inventoryNFTTypeId(
    //     address _account,
    //     string memory _type,
    //     uint256 _typeId
    // ) external view returns (Inventory memory _inventory) ;
    // function inventoryNFTOf(address _account, string memory _type)
    //     external
    //     view
    //     returns (Inventory[] memory _inventory);
   

}
