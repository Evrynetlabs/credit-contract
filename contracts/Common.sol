pragma solidity ^0.5.0;

/**
    Note: Simple contract to use as base for const vals
*/
contract Common {
    bytes4 internal constant EER2_ACCEPTED = 0x09a23c29; // bytes4(keccak256("onEER2Received(address,address,uint256,uint256,bytes)"))
    bytes4 internal constant EER2_BATCH_ACCEPTED = 0xbaf5f228; // bytes4(keccak256("onEER2BatchReceived(address,address,uint256[],uint256[],bytes)"))
}
