pragma solidity ^0.5.0;

import "../../contracts/IEER2TokenReceiver.sol";
import "./ThrowProxy.sol";


contract PayableThrowProxy is ThrowProxy, IEER2TokenReceiver {
    event Received(address _operator, address _from, uint256 _typeID, uint256 _value, bytes _data);
    event BatchReceived(
        address _operator,
        address _from,
        uint256[] _typeIDs,
        uint256[] _values,
        bytes _data
    );

    constructor(address _target) public ThrowProxy(_target) {}

    /////////////////////////////////////////// IEER2TokenReceiver //////////////////////////////////////////////

    function onEER2Received(
        address _operator,
        address _from,
        uint256 _typeID,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4) {
        emit Received(_operator, _from, _typeID, _value, _data);
        return 0x09a23c29;
    }

    function onEER2BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _typeIDs,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4) {
        emit BatchReceived(_operator, _from, _typeIDs, _values, _data);
        return 0xbaf5f228;
    }
}
