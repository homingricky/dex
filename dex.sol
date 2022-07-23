pragma solidity 0.6.3;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol';

contract Dex {
    struct Token {
        bytes32 ticker;
        address tokenAddress;
    }

    enum Side {
        BUY,
        SELL
    }

    struct Order {
        uint id;
        Side side;
        bytes32 ticker;
        uint amount;
        uint filled;
        uint price;
        uint time;
    }

    // bytes32 is key type
    // Token is value type
    // tokens is name of the array
    mapping(bytes32 => Token) public tokens;
    mapping(address => mapping(bytes32 => uint)) public traderBalances;
    // bytes32 list
    bytes32[] public tokenList;

    mapping(bytes32 => mapping(uint => Order[])) public orderBook;
    uint public nextOrderId;
    bytes32 constant DAI = bytes32('DAI');

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

    // Order Related Functions
    function createLimitOrder(bytes ticker, uint amount, uint price, Side side) tokenExist(ticker) external {
        require(ticker != DAI, 'cannot trade DAI');

        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Insufficient balance to sell');
        }
        else {
            require(traderBalances[msg.sender][DAI] >= amount * price, 'Insufficient DAI balance to buy');
        }

        Order[] storage orders = orderbook[ticker[uint(side)]];
        orders.push(Order(nextOrderId,side,ticker,amount,0,price,now));

        uint i = orders.length - 1;
        while (i > 0) {
            if (side == Side.BUY && orders[i-1].price > orders[i].price) {
                break;
            }
            if (side == Side.SELL && orders[i-1].price < orders[i].price) {
                break;
            }
            Order memory temp_order = orders[i-1];
            orders[i-1] = orders[i];
            orders[i] = temp_order;
            i--;
            }
            nextOrderId++;
        }
    }

