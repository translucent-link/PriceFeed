// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Node.sol";
import "./ChainlinkOracleRequester.sol";
import "./OracleRequester.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";

contract PriceFeed is Ownable, ChainlinkClient {
    mapping(address => Node) nodes;
    address[] public oracles;
    uint256 public minimumOracles;
    uint256 public maximumOracles;
    uint256 public payment;
    OracleRequester oracleRequester;

    constructor(
        uint256 _minimumOracles,
        uint256 _maximumOracles,
        uint256 _payment
    ) {
        minimumOracles = _minimumOracles;
        maximumOracles = _maximumOracles;
        payment = _payment;
        oracleRequester = new ChainlinkOracleRequester();
    }

    function noOracles() public view returns (uint256) {
        return oracles.length;
    }

    function setPayment(uint256 _payment) public onlyOwner {
        payment = _payment;
    }

    function setOracleRequester(OracleRequester _requester) public onlyOwner {
        oracleRequester = _requester;
    }

    function addOracle(address _oracle, string memory _jobId) public onlyOwner {
        require(_oracle != address(0), "Oracle cannot be 0x0");
        Node memory node = nodes[_oracle];
        require(node.oracle != _oracle, "Oracle already added");
        nodes[_oracle] = Node(_oracle, _jobId);
        oracles.push(_oracle);
    }

    function removeOracle(address _oracle) public onlyOwner {
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

    function setMinimumOracles(uint256 _minimumOracles) public onlyOwner {
        require(_minimumOracles > 0, "Minimum oracles must be greater than 0");
        require(
            oracles.length >= _minimumOracles,
            "Unable to set minimum oracles, increase current oracles"
        );
        minimumOracles = _minimumOracles;
    }

    function setMaximumOracles(uint256 _maximumOracles) public onlyOwner {
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
                payment,
                this.requestCallback.selector
            );
        }
    }

    function requestCallback(bytes32 _requestId, uint256 newPrice)
        public
        recordChainlinkFulfillment(_requestId)
    {}
}
