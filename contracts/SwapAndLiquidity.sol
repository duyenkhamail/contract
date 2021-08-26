pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapAndLiquidity.sol";
import "./PancakeRouter.sol";

contract SwapAndLiquidity is Ownable, ISwapAndLiquidity {
    using SafeMath for uint256;
    IERC20 private mainToken;
    IPancakeSwapV2Router02 public pancakeSwapV2Router;
    address public pancakeSwapV2Pair;
    address public stakingContractAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public minBalanceToAddLiquidity = 1000 * 10**9;

    uint256 public _liquidityFee = 50;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
      // Set liquidity attributes
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

  

    function setMinBalanceToAddLiquidity(uint256 _balance)
        external
        onlyOwner()
    {
        minBalanceToAddLiquidity = _balance;
    }

    function setPancakeSwapRouter(address _router) external onlyOwner() {
        pancakeSwapV2Router = IPancakeSwapV2Router02(_router);
    }

    function setPancakeSwapPair(address _pair) external onlyOwner() {
        pancakeSwapV2Pair = _pair;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(mainToken);
        path[1] = pancakeSwapV2Router.WETH();

        mainToken.approve(address(pancakeSwapV2Router), tokenAmount);

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        mainToken.approve(address(pancakeSwapV2Router), tokenAmount);

        // add the liquidity
        pancakeSwapV2Router.addLiquidityETH{value: ethAmount}(
            address(mainToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
    function addTokenToLiquidity() external override{
         uint256 newBalance = mainToken.balanceOf(address(this));
        if (
            swapAndLiquifyEnabled &&
            newBalance > minBalanceToAddLiquidity &&
            !inSwapAndLiquify &&
            address(pancakeSwapV2Router) != address(0)
            
        ) {
            swapAndLiquify(minBalanceToAddLiquidity);
        }
    }
}
