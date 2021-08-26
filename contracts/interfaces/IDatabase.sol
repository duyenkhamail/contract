interface IDatabase {
    function mergeEggs(uint256 _egg1, uint256 _egg2) external view returns(uint256 _combinedEgg);
}