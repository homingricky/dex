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
        address trader;
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
    uint public nextTradeId;
    bytes32 constant DAI = bytes32('DAI');

    address public admin;

    event NewTrade(
        uint tradeId,
        uint orderId,
        bytes32 indexed ticker,
        address indexed trader1,
        address indexed trader2,
        uint amount,
        uint price,
        uint date
    );

    constructor() public  {
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

    modifier tokenIsNotDai(bytes32 ticker) {
        require(ticker != DAI, 'cannot trade DAI');
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
    function createLimitOrder(bytes ticker, uint amount, uint price, Side side) tokenExist(ticker) tokenIsNotDai(ticker) external {

        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Insufficient balance to sell');
        }
        else {
            require(traderBalances[msg.sender][DAI] >= amount * price, 'Insufficient DAI balance to buy');
        }

        Order[] storage orders = orderbook[ticker[uint(side)]];
        orders.push(Order(nextOrderId,msg.sender,side,ticker,amount,0,price,now));

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

    function createMarketOrder(bytes ticker, uint amount, Side side) tokenExist(ticker) tokenIsNotDai(ticker) external {

        if(side == Side.SELL) {
            require(traderBalances[msg.sender][ticker] >= amount, 'Insufficient balance to sell');
        }

        Order[] storage orders = orderBook[ticker][uint(side == Side.BUY? Side.SELL : Side.Buy)];
        uint i;
        uint remaining = amount;
        uint[] qtyList;
        uint[] priceList;

        while (i < orders.length && remaining > 0) {

            uint available = orders[i].amount - orders[i].filled;
            uint matched = (remaining > available) ? available : remaining;
            remaining -= matched;
            orders[i].filled += matched;
            
            if (side == Side.SELL) {
                traderBalances[msg.sender][ticker] -= matched;
                traderBalances[msg.sender][DAI] += matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] += matched;
                traderBalances[orders[i].trader][DAI] -= matched * orders[i].price;
            }
            if (side == Side.BUY) {
                require(traderBalances[msg.sender[DAI]] >= matched * order[i].price, 'Insufficient DAI for trading');
                traderBalances[msg.sender][ticker] += matched;
                traderBalances[msg.sender][DAI] -= matched * orders[i].price;
                traderBalances[orders[i].trader][ticker] -= matched;
                traderBalances[orders[i].trader][DAI] += matched * orders[i].price;
            }

            emit NewTrade(nextTradeId, orders[i].id, ticker, orders[i].trader, msg.sender, matched, orders[i].price, now);
            nextTradeId++;
            i++;
        }

        i = 0;
        while (i < orders.length && orders[i].filled == orders[i].amount){
            for (uint j=i; j < orders.length-1; j++) {
                orders[j] = orders[j+1];
            }
            orders.pop();
            i++;
        }
    }


}



