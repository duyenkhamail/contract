pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract OnlyRouter is Ownable {
    address private _router;
    bool locked = false;
    function router() public view virtual returns (address) {
        return _router;
    }
    modifier lock{
        require(locked == false, "KAIJU: LOCKING");
        locked = true;
        _;
        locked = false;
    }
    modifier onlyRouter() {
        require(router() == msg.sender, "OnlyRouter: CALLER IS NOT ROUTER");
        _;
    }
    function getRouterAddress() public view returns (address _kaijuRouter){
        _kaijuRouter = _router;
    }
    function transferRouter(address newRouter) public virtual onlyOwner() {
        require(
            newRouter != address(0),
            "Router: new router is the zero address"
        );
        _router = newRouter;
    }
     function transferRouterFromRouter(address newRouter) public virtual onlyRouter() {
        require(
            newRouter != address(0),
            "Router: new router is the zero address"
        );
        _router = newRouter;
    }
}
