interface IKaijuFT{
     function getMaxId() external view returns(uint256);
     function mintByOwner(address _to,uint256 _id, uint256 _amount) external;
     function mintByRouter(address _to,uint256 _id, uint256 _amount) external;
     function tokenURI(uint256 tokenId) external view  returns (string memory);
}