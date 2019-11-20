pragma solidity >=0.4.16 <0.6.0;

contract OracleContract {

    // declare constants

    // contract owner
    address private owner;
    // nonce used to add pseudo randomness
    uint8 private nonce = 0;
    // registration fee required for oracle registration
    uint256 public constant REGISTRATION_FEE = 1 ether;
    // number of responses to verify the oracle response
    uint256 private constant MIN_RESPONSES = 3;
    // keep the record of all oracles
    mapping(address => uint8[3]) oracles;

    // model for responses from oracles
    struct ResponseInfo {
        address requester;
        bool isOpen;
        mapping(uint8 => address[]) responses;
    }
    // token price data
    struct TokenPrice {
        bool hasStatus;
        uint8 price;
    }

    // keep record of all oracle responses
    mapping(bytes32 => ResponseInfo)private oracleResponses;
    // keep record of token price
    mapping(bytes32 => TokenPrice)tokens;

    // event fired when a data request is made
    event DataRequest(uint8 index, string token, uint256 timestamp);

    // event fired when an oracle submits response
    event TokenPriceInfo(string token, uint256 timestamp, uint8 price, bool verified);

    constructor()public{
        owner = msg.sender;
    }

    // only owner modifier
    modifier requireContractOwner(){
        require(msg.sender == owner, 'Caller is not a contract owner');
        _;
    }

    // register oracle function
    function registerOracle() external payable {
        // require registration fee
        require(msg.value >= REGISTRATION_FEE, 'Registration fee is required');

        // get random indexes
        uint8[3] memory indexes = generateIndexes(msg.sender);
        // assign the indexes to oracles
        oracles[msg.sender] = indexes;
    }

    // get oracles
    function getOracle(address account) external view requireContractOwner returns (uint8[3] memory){
        return oracles[account];
    }

    // request data function
    function fetchTokenPrice(string token, uint256 timestamp) external {
        // generate a random number between 0-9 which oracle may respond
        uint8 index = getRandomIndex(msg.sender);

        // generate a unique key and assign it to the request
        bytes32 key = keccak256(abi.encodePacked(index, token, timestamp));
        oracleResponses[key] = ResponseInfo({
            requester : msg.sender,
            isOpen : true
            });

        // emit the event to notify the oracles that match the index
        emit DataRequest(index, token, timestamp);
    }

    // submit oracle response function
    function submitOracleResponse(uint8 index, string token, uint256 timestamp, uint8 price) external {
        require((oracles[msg.sender][0] == index) || (oracles[msg.sender][1] == index) || (oracles[msg.sender][2] == index), 'Index does not match request');
        // check that response is being submitted for an open request
        bytes32 key = bytes32(keccak256(abi.encodePacked(index, token, timestamp)));
        require((oracleResponses[key].isOpen), 'Request is not open');

        // store response
        oracleResponses[key].responses[price].push(msg.sender);

        // information is not considered verified until at least MIN_RESPONSES
        if (oracleResponses[key].responses[price].length >= MIN_RESPONSES) {
            // close the request
            oracleResponses[key].isOpen = false;
            // emit the token price info event
            emit TokenPriceInfo(token, timestamp, price, true);

            // save the price info
            bytes32 tokenKey = keccak256(abi.encodePacked(token, timestamp));
            tokens[tokenKey] = TokenPrice(true, price);
        } else {
            emit TokenPriceInfo(token, timestamp, price, false);
        }
    }

    // utility functions

    // generate indexes
    function generateIndexes(address account) internal returns (uint8[3] memory){
        uint8[3] memory indexes;
        // first random index
        indexes[0] = getRandomIndex(account);
        // 2nd random index
        indexes[1] = indexes[0];
        // check if 2nd index is same, then get another random
        while (indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }
        // 3rd random index
        indexes[2] = indexes[1];
        while ((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }
        return indexes;
    }

    // generate a random number from 0-9
    function getRandomIndex(address account) internal returns (uint8){
        uint8 maxValue = 10;
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        // solidity can fetch hashes for last 256 blocks
        if (nonce > 250) {
            nonce = 0;
        }
        return random;
    }
}