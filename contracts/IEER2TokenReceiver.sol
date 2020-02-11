pragma solidity ^0.5.0;

/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface IEER2TokenReceiver {
    /**
        @notice Handle the receipt of a single EER2 token type.
        @dev An EER2-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onEER2Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _typeID    The ID of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onEER2Received(address,address,uint256,uint256,bytes)"))`
    */
    function onEER2Received(
        address _operator,
        address _from,
        uint256 _typeID,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    /**
        @notice Handle the receipt of multiple EER2 token types.
        @dev An EER2-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onEER2BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _typeIDs   An array containing typeIDs of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _typeIDs array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onEER2BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onEER2BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _typeIDs,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}
