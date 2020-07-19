pragma solidity ^0.5.0;

import "../../tracing/Assessment.sol";

contract AssessmentV1 is Assessment {

    uint256 private _tokenId;
    address private _evaluator;
    string private _data;
    string private _hash;
    uint256 private _assessBlockNumber;
    uint256 private _assessTime;

    constructor(uint256 tokenId
    , string memory data
    , string memory hash) public {
        _evaluator = msg.sender;
        _tokenId = tokenId;
        _data = data;
        _hash = hash;
        _assessBlockNumber = block.number;
        _assessTime = now;
    }

    function evaluator() external view returns (address){
        return _evaluator;
    }

    function data() external view returns (string memory){
        return _data;
    }

    function hash() external view returns (string memory){
        return _hash;
    }

    function tokenId() external view returns (uint256){
        return _tokenId;
    }

    function assessBlockNumber() external view returns (uint256){
        return _assessBlockNumber;
    }

    function assessTime() external view returns (uint256){
        return _assessTime;
    }
}
