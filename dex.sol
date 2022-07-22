pragma solidity 0.6.3;

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    // bytes32 is key type
    // Token is value type
    // tokens is name of the array
    mapping(bytes32 => Token) public tokens;

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

    function addToken(bytes32 ticker, address tokenAddress) onlyAdmin() external {
        tokens[ticker] = Token(ticker, tokenAddress);
        tokenList.push(ticker);
    }
    
    
}