interface IEggs {
    function buyEggs(uint256 _id, uint256 _amount) external returns(uint256 _result);
    function mergeEggs(uint256 egg1, uint256 egg2) external returns(uint256 _combinedEgg);
}
