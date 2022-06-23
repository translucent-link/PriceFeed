// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract PriceFeed {
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

    function addOracle(address _oracle, string memory _jobId) public {
        require(_oracle != address(0), "Oracle cannot be 0x0");
        Node memory node = nodes[_oracle];
        require(node.oracle != _oracle, "Oracle already added");
        nodes[_oracle] = Node(_oracle, _jobId);
        oracles.push(_oracle);
    }

    function removeOracle(address _oracle) public {
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

    function setMinimumOracles(uint256 _minimumOracles) public {
        require(_minimumOracles > 0, "Minimum oracles must be greater than 0");
        require(
            oracles.length >= _minimumOracles,
            "Unable to set minimum oracles, increase current oracles"
        );
        minimumOracles = _minimumOracles;
    }

    function setMaximumOracles(uint256 _maximumOracles) public {
        require(_maximumOracles > 0, "Maximum oracles must be greater than 0");
        require(
            oracles.length <= _maximumOracles,
            "Unable to set maximum, reduce current oracles"
        );
        maximumOracles = _maximumOracles;
    }
}
