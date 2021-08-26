pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFactory.sol";
library KaijuLibrary {
    function safeTransferNFT(IFactory factory, string memory _type, uint256 _tokenId, address _from, address _to) internal{

        address nftAddress = factory.getNFTContract(_type);
        require(nftAddress != address(0), "Kaiju: INVALID NFT");
        
        IERC721 nftContract = IERC721(nftAddress);
        nftContract.transferFrom(_from,_to, _tokenId);
    }
     function safeTransferFT(IFactory factory, string memory _type,  uint256 _tokenId, address _from, address _to, uint256 _amount) internal{

        address nftAddress = factory.getFTContract(_type);
        require(nftAddress != address(0), "Kaiju: INVALID FT");
        
        IERC1155 ftContract = IERC1155(nftAddress);
        ftContract.safeTransferFrom(_from,_to, _tokenId,_amount, "0x");
    }
    function getBurnAddress() internal pure returns (address) {
        return 0x000000000000000000000000000000000000dEaD;
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "BNB_TRANSFER_FAILED");
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + (j % 10)));
            j /= 10;
        }
        str = string(bstr);
    }

}
