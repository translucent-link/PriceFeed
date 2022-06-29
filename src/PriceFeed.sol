// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Node.sol";
import "./ChainlinkOracleRequester.sol";
import "./OracleRequesterInterface.sol";
import "./PriceReceiverInterface.sol";

contract PriceFeed is Ownable, PriceReceiverInterface {
    mapping(address => Node) private nodes;
    address[] private oracles;
    uint256 private minimumOracles;
    uint256 private maximumOracles;
    uint256 private payment;
    OracleRequesterInterface oracleRequester;

    uint256[] public prices;
    bytes32[] public requestIds;
    uint256 public price;
    uint256 public lastUpdatedTimestamp;
    uint256 public updatesReceived;

    constructor(
        uint256 _minimumOracles,
        uint256 _maximumOracles,
        uint256 _payment
    ) {
        minimumOracles = _minimumOracles;
        maximumOracles = _maximumOracles;
        payment = _payment;
        oracleRequester = new ChainlinkOracleRequester(address(this));
        updatesReceived = 0;
    }

    function noOracles() external view returns (uint256) {
        return oracles.length;
    }

    function setPayment(uint256 _payment) external onlyOwner {
        payment = _payment;
    }

    function getPaymnent() external view returns (uint256) {
        return payment;
    }

    function getMinimumOracles() external view returns (uint256) {
        return minimumOracles;
    }

    function getMaximumOracles() external view returns (uint256) {
        return maximumOracles;
    }

    function setOracleRequester(OracleRequesterInterface _requester)
        external
        onlyOwner
    {
        oracleRequester = _requester;
    }

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

    function removeOracle(address _oracle) external onlyOwner {
        require(_oracle != address(0), "Oracle cannot be 0x0");
        Node memory node = nodes[_oracle];
        require(node.oracle == _oracle, "Oracle not added");
        nodes[_oracle] = Node(address(0), "");
        deleteOracle(_oracle);
    }

    function indexOfOracle(address _oracle) private view returns (int256) {
        for (uint256 i = 0; i < oracles.length; i++) {
            if (oracles[i] == _oracle) {
                return int256(i);
            }
        }
        return -1;
    }

    function deleteOracle(address _oracle) private {
        int256 index = indexOfOracle(_oracle);
        require(index != -1, "Oracle not added");
        oracles[uint256(index)] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function setMinimumOracles(uint256 _minimumOracles) external onlyOwner {
        require(_minimumOracles > 0, "Minimum oracles must be greater than 0");
        require(
            oracles.length >= _minimumOracles,
            "Unable to set minimum oracles, increase current oracles"
        );
        minimumOracles = _minimumOracles;
    }

    function setMaximumOracles(uint256 _maximumOracles) external onlyOwner {
        require(_maximumOracles > 0, "Maximum oracles must be greater than 0");
        require(
            oracles.length <= _maximumOracles,
            "Unable to set maximum, reduce current oracles"
        );
        maximumOracles = _maximumOracles;
    }

    function updatePrice() external onlyOwner {
        require(oracles.length >= minimumOracles, "Not enough oracles");
        require(oracles.length <= maximumOracles, "Too many oracles");
        for (uint256 i = 0; i < oracles.length; i++) {
            address oracle = oracles[i];
            Node memory node = nodes[oracle];
            bytes32 requestId = oracleRequester.makeRequestToNode(
                node,
                payment
            );
            requestIds.push(requestId);
        }
    }

    function receivePrice(bytes32, uint256 _newPrice) external {
        prices.push(_newPrice);
        updatesReceived++;
        if (updatesReceived == oracles.length) {
            price = average(prices);
            lastUpdatedTimestamp = block.timestamp;
            delete prices;
            delete requestIds;
            updatesReceived = 0;
        }
    }

    function average(uint256[] memory _prices) public pure returns (uint256) {
        uint256 _accumulator = 0;
        for (uint256 i = 0; i < _prices.length; i++) {
            _accumulator += _prices[i];
        }
        return _accumulator / _prices.length;
    }
}
