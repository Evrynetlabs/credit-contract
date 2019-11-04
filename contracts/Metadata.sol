pragma solidity ^0.5.0;

import "./IMetadata.sol";

contract Metadata is IMetadata {
    struct meta {
        string name;
        string code;
        string issuer;
        string jsonURL;
        uint16 decimals;
    }

    mapping(uint256 => meta) private metas;

    function register(uint256 _id, string memory _name, string memory _code, string memory _issuer, string memory
                      _jsonURL, uint16 _decimals) internal {
        metas[_id] = meta(_name, _code, _issuer, _jsonURL, _decimals);
    }

    function name(uint256 _id) view external returns(string memory){
        return metas[_id].name;    
    }

    function code(uint256 _id) view external returns(string memory){
        return metas[_id].code;    
    }

    function issuer(uint256 _id) view external returns(string memory){
        return metas[_id].issuer;    
    }

    function decimals(uint256 _id) view external returns(uint16){
        return metas[_id].decimals;    
    }

    function jsonURL(uint256 _id) view external returns(string memory){
        return metas[_id].jsonURL;    
    }
}
