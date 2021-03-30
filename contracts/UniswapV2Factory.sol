pragma solidity =0.5.16;

import './interfaces/IUniswapV2Factory.sol';
import './UniswapV2Pair.sol';

contract UniswapV2Factory is IUniswapV2Factory {
    address public feeTo;  //收税地址
    address public feeToSetter; // 收税权限控制地址

    // 配对映射, 地址 => (地址, 地址)
    mapping(address => mapping(address => address)) public getPair;
    
    // 所有配对数组
    address[] public allPairs;

    // 配对创建事件, uint 为配对偏好
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    /** 
      * @dev 构造函数
      * @param _feeToSetter 收税开关权限
     */
    constructor(address _feeToSetter) public {
        feeToSetter = _feeToSetter;
    }

    // 获取所有配对的数量
    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    /**
     * @param tokenA TokenA
     * @param tokenB TokenB
     * @return 配对地址
     * @dev 创建配对
     */

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        // 确认两个地址不相等
        require(tokenA != tokenB, 'UniswapV2: IDENTICAL_ADDRESSES');
        // 确保 tokenA 的地址大于 tokenB(因为地址本质是一个 16 进制数)
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        // token0 地址不能是零地址
        require(token0 != address(0), 'UniswapV2: ZERO_ADDRESS');
        // 现有配对地址中没有 token0 => token1
        require(getPair[token0][token1] == address(0), 'UniswapV2: PAIR_EXISTS'); // single check is sufficient
        // 为配对合约创建字节码
        bytes memory bytecode = type(UniswapV2Pair).creationCode;
        // 将 token0 与 token1 打包并创建字节码
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        // 内联汇编
        assembly {
            // 部署合约并添加 salt, 然后返回配对地址
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        // 调用 pair 合约中的初始化方法
        IUniswapV2Pair(pair).initialize(token0, token1);
        // 在配对映射中设置 token0=>token1=pair
        getPair[token0][token1] = pair;
        // 在配对映射中设置 token0=>token1=pair
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        // 在配对地址中加入 pair 地址
        allPairs.push(pair);
        // 触发配对成功事件
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    /**
     * @dev 设置收税地址
     * @param _feeTo 收税地址
     */
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    // 转让收税控制权
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
