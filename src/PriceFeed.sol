// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Node.sol";
import "./ChainlinkOracleRequester.sol";
import "./OracleRequesterInterface.sol";
import "./PriceReceiverInterface.sol";
import "./Math.sol";

contract PriceFeed is Ownable, PriceReceiverInterface {
    // a registry of address and nodes;
    mapping(address => Node) private nodes;

    // list of permitted oracle addresses
    address[] public oracles;

    // mimimum number of oracles required to trigger a price update
    uint256 public minimumOracles;

    // maximum number of oracles allowed to trigger a price update
    uint256 public maximumOracles;

    // the payment in LINK that each oracle is awarded for each price update
    uint256 public payment;

    // contains the Chainlink client for request & callback
    OracleRequesterInterface public oracleRequester;

    // list of prices received from oracles - so far
    uint256[] public prices;

    // latest calculated price
    uint256 public price;

    // block timestamp of the last price update
    uint256 public lastUpdatedTimestamp;

    // number of price updates received - so far
    uint256 public updatesReceived;

    // Emitted when a price update is requested.
    event PriceRequested(address indexed oracle, string indexed jobId);

    // Emitted when all oracles have reported in and the price is updated
    event PriceUpdated(
        address indexed updatedBy,
        uint256 indexed price,
        uint256 timestamp
    );

    // Creates a new PriceFeed contract with specified minimum and maximum number of oracles as well as LINK payment details.
    constructor(
        uint256 _minimumOracles,
        uint256 _maximumOracles,
        uint256 _payment,
        address _linkTokenAddress
    ) {
        minimumOracles = _minimumOracles;
        maximumOracles = _maximumOracles;
        payment = _payment;
        oracleRequester = new ChainlinkOracleRequester(this, _linkTokenAddress);
        updatesReceived = 0;
    }

    // Returns the number of oracles registered with this PriceFeed contract.
    function noOracles() external view returns (uint256) {
        return oracles.length;
    }

    // Updates the LINK payment amount that each oracle receives.
    function setPayment(uint256 _payment) external onlyOwner {
        payment = _payment;
    }

    // Updates the OracleRequest used to make ChainlinkRequests. Typically only used for testing.
    function setOracleRequester(OracleRequesterInterface _requester)
        external
        onlyOwner
    {
        oracleRequester = _requester;
    }

    // Adds an oracle to the list of permitted oracles.
    function addOracle(address _oracle, string memory _jobId)
        external
        onlyOwner
    {
        require(_oracle != address(0), "Oracle cannot be 0x0");
        Node memory node = nodes[_oracle];
        require(node.oracle != _oracle, "Oracle already added");
        nodes[_oracle] = Node(_oracle, _jobId);
        oracles.push(_oracle);
    }

    // Removes an oracle from the list of permitted oracles.
    function removeOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle cannot be 0x0");
        Node memory node = nodes[_oracle];
        require(node.oracle == _oracle, "Oracle not added");
        nodes[_oracle] = Node(address(0), "");
        deleteOracle(_oracle);
    }

    // Returns the index of the oracle in the list of oracles. Returns -1 if not found.
    function indexOfOracle(address _oracle) private view returns (int256) {
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i] == _oracle) {
                return int256(i);
            }
        }
        return -1;
    }

    // Internal function that deletes an oracle from the list of permitted oracles and compacts the list.
    function deleteOracle(address _oracle) private {
        int256 index = indexOfOracle(_oracle);
        require(indexOfOracle(_oracle) != -1, "Oracle not added");
        oracles[uint256(index)] = oracles[oracles.length - 1];
        oracles.pop();
    }

    // Updates the minimum number of oracles required to trigger a price update. Checks to see if the new minimum is less than the current number of oracles.
    function setMinimumOracles(uint256 _minimumOracles) external onlyOwner {
        require(_minimumOracles > 0, "Minimum oracles must be greater than 0");
        require(
            oracles.length >= _minimumOracles,
            "Unable to set minimum oracles, increase current oracles"
        );
        minimumOracles = _minimumOracles;
    }

    // Updates the maximum number of oracles allowed to trigger a price update. Checks to see if the new maximum is greater than the current number of oracles.
    function setMaximumOracles(uint256 _maximumOracles) external onlyOwner {
        require(_maximumOracles > 0, "Maximum oracles must be greater than 0");
        require(
            oracles.length <= _maximumOracles,
            "Unable to set maximum, reduce current oracles"
        );
        maximumOracles = _maximumOracles;
    }

    // Initiates a series of price update requests with oracles
    function updatePrice() external onlyOwner {
        require(oracles.length >= minimumOracles, "Not enough oracles");
        require(oracles.length <= maximumOracles, "Too many oracles");
        for (uint256 i = 0; i < oracles.length; i++) {
            address oracle = oracles[i];
            Node memory node = nodes[oracle];
            emit PriceRequested(oracle, node.jobId);
            oracleRequester.makeRequestToNode(node, payment);
        }
    }

    // Records a price update from an oracle. If all oracles have reported, the price is calculated and the PriceUpdated event is emitted.
    function receivePrice(bytes32, uint256 _newPrice) external override {
        require(msg.sender == address(oracleRequester), "Not a valid sender");
        prices.push(_newPrice);
        updatesReceived++;
        if (updatesReceived == oracles.length) {
            price = Math.average(prices);
            lastUpdatedTimestamp = block.timestamp;
            delete prices;
            updatesReceived = 0;
            emit PriceUpdated(msg.sender, price, lastUpdatedTimestamp);
        }
    }
}
