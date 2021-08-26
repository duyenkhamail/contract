pragma solidity ^0.8.0;

interface INFT {
     struct TokenAttributes {
        uint256 TokenId;
        uint256 IdInType;
        uint256 TypeId;
        uint256 Rarity;
        uint256 Quality;
    }
    function getType() external view returns (string memory);

    function increaseNFTCount(uint256 _idInType,uint256 _num) external;


    function getTotalNFT(uint256 _idInType) external view returns (uint256);

    function setPrice(uint256 _price) external;

    function getPrice() external view returns (uint256);
 function getTokenAttributes(uint256  _tokenId)
        external
        view
        
        returns (TokenAttributes memory tokenAttributes
        );

   
    function getTokensWithUriOfOwner(address _owner)
        external
        view
        returns (uint256[] memory _ids, string[] memory _uri);

      function getTokensWithAttributesOwner(address _owner)
        external
        view
        
        returns (TokenAttributes[] memory tokenAttributes
        );

    function getTokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory _ids);

    function mintNFT(
        address account,
        uint256 _idInType,
        uint256 _rarity,
        uint256 _quality
    )
        external
        returns (
            bool openResult,
            string memory message,
            uint256 nftId
        );

    function setBaseUri(string memory _uri) external;

    function burnNFT(address account, uint256 id) external;

    function maxSupply(uint256 _idInType) external view returns (uint256);
}
