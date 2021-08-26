interface IFactory {
    function getFTContract(string memory _type) external view returns (address);

    function getNFTContract(string memory _type)
        external
        view
        
        returns (address);
}
