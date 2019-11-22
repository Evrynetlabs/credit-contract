pragma solidity ^0.5.0;

contract ThrowProxy {
    address public target;
    bytes data;

    constructor(address _target) public{
        target = _target;
    }

    //prime the data using the fallback function.
    function() external payable{
        data = msg.data;
    }

    function execute() external returns (bool, bytes memory) {
        uint balance = address(this).balance;
        if ( balance > 0){
            return target.call.value(address(this).balance)(data);
        }
        return target.call(data);
    }
}