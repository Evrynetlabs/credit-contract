pragma solidity ^0.5.0;

import "../../contracts/IERC1155TokenReceiver.sol";

contract ThrowProxy is IERC1155TokenReceiver{

    event Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data);
    event BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data);

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

    /////////////////////////////////////////// IERC1155TokenReceiver //////////////////////////////////////////////

    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4){
        emit Received(_operator, _from, _id, _value, _data);
        return 0xf23a6e61;
    }

    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4){
        emit BatchReceived(_operator, _from, _ids, _values, _data);
        return 0xbc197c81;
    }
}