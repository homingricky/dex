pragma solidity 0.6.3;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    // bytes32 is key type
    // Token is value type
    // tokens is name of the array
    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    // bytes32 list
    bytes32[] public tokenList;
    address public admin;

    constructor() public {
        admin = msg.sender;
    }

    // modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, 'only admin');
        _;
    }

    // check if token exists in this dex contract
    modifier tokenExist(bytes32 ticker) {
        console.log(tokens[ticker].tokenAddress);
        require(tokens[ticker].tokenAddress != address(0), "This token does not exist in the dex");
        _;
    }

    function addToken(bytes32 ticker, address tokenAddress) onlyAdmin() external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    function deposit(uint amount, bytes32 ticker) tokenExist(ticker) external {
        IERC20(tokens[ticker].tokenAddress).transferFrom(msg.sender, address(this), amount);
        traderBalances[msg.sender][ticker] += amount;
    }

    function withdraw(uint amount, bytes32 ticker) tokenExist(ticker) external {
        require(traderBalances[msg.sender][ticker] >= amount, "Insufficient balance");
        traderBalances[msg.sender][ticker] -= amount;
        IERC20(tokens[ticker].tokenAddress).transfer(msg.sender, amount);
    }

    //test github branch protection
}