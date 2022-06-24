// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "chainlink-brownie-contracts/contracts/src/v0.8/ChainlinkClient.sol";

contract PriceFeed is Ownable, ChainlinkClient {
    struct Node {
        address oracle;
        string jobId;
    }

    mapping(address => Node) nodes;
    address[] public oracles;
    uint256 public minimumOracles;
    uint256 public maximumOracles;

    constructor(uint256 _minimumOracles, uint256 _maximumOracles) {
        minimumOracles = _minimumOracles;
        maximumOracles = _maximumOracles;
    }

    function noOracles() public view returns (uint256) {
        return oracles.length;
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
            bytes32 requestId = makeRequest(
                node.oracle,
                stringToBytes32(node.jobId)
            );
        }
    }

    function makeRequest(address _oracle, bytes32 _jobId)
        private
        returns (bytes32 requestId)
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            _oracle,
            _jobId,
            requestCallback.selector
        );
    }

    function requestCallback(bytes32 _requestId, uint256 newPrice)
        public
        recordChainlinkFulfillment(_requestId, newPrice)
    {
        Chainlink.Response memory res = Chainlink.Response(_result);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }
}
