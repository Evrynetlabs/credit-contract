pragma solidity ^0.5.0;

import "./ICredit.sol";
import "./IReceiver.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Metadata.sol";


contract Credit is ICredit, Metadata {

    using SafeMath for uint256;
    using Address for address;

    // owner => (id => balance)
    mapping(address => mapping(uint256 => uint256)) private balances; 
    // id => totalSupply
    mapping(uint256 => uint256) private totalSupplies; 
    // owner => (broker => (id => status))
    mapping(address => mapping(address => mapping(uint256 => bool))) private eachApproved; 
    // owner => (broker => status)
    mapping(address => mapping(address => bool)) private allApproved; 
    // id => creator
    mapping(uint256 => address) private creators; 

    // counter up credit id
    uint256 private currentID;

    function _transfer(address _sender, address _from, address _to, uint256 _id, uint256 _value) internal {
        require(_id <= currentID, "Credit: invalid credit ID.");
        require(eachApproved[_from][_sender][_id] || allApproved[_from][_sender] || _sender == _from,
                "Credit: sender is not allowed to transfer.");
        require(balances[_from][_id] >= _value, "Credit: insuffient fund.");
        require(_from != address(0) && _to != address(0), "Credit: address zero is not allowed.");

        _isCallable(_to, _id);

        balances[_from][_id] = balances[_from][_id].sub(_value);
        balances[_to][_id] = balances[_to][_id].add(_value);
    }

    function _isCallable(address _to, uint256 _id) view internal {
        if (_to.isContract()) {
            require(Receiver(_to).creditable(_id), "Credit: the contract does not accept the credit.");
        }
    }

    /**
        Typical single transfer with one sender one receiver and a single credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement IReceiver.
        MUST emit Transfer event.
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the credit type
        @param _value   Transfer amount
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external {
        _transfer(msg.sender, _from, _to, _id, _value);

        emit Transfer(msg.sender, _from, _to, _id, _value);
    }

    /**
        Multiple transfer with one sender one receiver and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement IReceiver.
        MUST be revert if number of `_ids` and `_values` does not eqaul.
        MUST emit BatchTransfer event.
        @param _from    Source address
        @param _to      Target address
        @param _ids     List of ID of the credit types
        @param _values  List of Transfer amounts. The number and order of them MUST eqaul to `_ids`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external {
        require(_ids.length == _values.length, "Credit: the number of id and value MUST be eqaul.");

        for(uint256 i = 0; i < _ids.length; ++i) {
            _transfer(msg.sender, _from, _to, _ids[i], _values[i]);
        }

        emit BatchTransfer(msg.sender, _from, _to, _ids, _values);
    }

    /**
        Multiple transfer with [multi-sender] [multi-receiver] and [muti-]credit type.
        @dev Caller must be approved or be an owner of the credit being transferred.
        MUST be revert if the `_id` is invalid.
        MUST be revert if no authorized to transfer.
        MUST be revert if `_from`'s `_id` balance less than `_value`.
        MUST be revert if `_from` or `_to` is the zero address.
        MUST be revert if `_to` is a smart contract but does not implement IReceiver.
        MUST be revert if number of `_froms` `_tos` `_ids` and `_values` does not eqaul.
        MUST emit FullBatchTransfer event.
        @param _froms    List of Source addresses
        @param _tos      List of Target addresses
        @param _ids      List of ID of the credit types
        @param _values   List of Transfer amounts
    */
    function safeFullBatchTransfer(address[] calldata _froms, address[] calldata _tos, uint256[] calldata _ids,
                                   uint256[] calldata _values) external {
        require(_froms.length.sub(_tos.length).add(_ids.length).sub(_values.length) == 0, 
                "Credit: the number of id and value MUST be eqaul.");

        for( uint256 i = 0; i < _froms.length; ++i) {
            _transfer(msg.sender, _froms[i], _tos[i], _ids[i], _values[i]);
        }

        emit FullBatchTransfer(msg.sender, _froms, _tos, _ids, _values);
    }

    /**
        Set a full authorized of a broker over a customer portfolio.
        @param _broker      Broker address
        @param _isApproved  true if give a full access to the broker. Otherwise, false
     */
    function setApproveForAll(address _broker, bool _isApproved) external {
        allApproved[msg.sender][_broker] = _isApproved;

        emit ApproveForAll(msg.sender, _broker);
    }

    /**
        Set an individual credit type authorized of a broker over a customer portfolio.
        @param _broker      Broker address
        @param _id          credit type id which the broker can control
        @param _isApproved  true if give a full access to the broker. Otherwise, false
    */
    function setApproveForEach(address _broker, uint256 _id, bool _isApproved) external {
        eachApproved[msg.sender][_broker][_id] = _isApproved;

        emit ApproveForEach(msg.sender, _broker, _id);
    }

    /**
        @notice Get a broker authorized status over a customer portfolio.
        @param _customer    Credit owner
        @param _broker      Broker address
        @param _id          credit type id which the broker can control
        @return broker status
    */
    function getApprove(address _customer, address _broker, uint256 _id) view external returns(bool) {
        if(allApproved[_customer][_broker] == true) {
            return true;
        } else {
            return eachApproved[_customer][_broker][_id];
        }
    }

    /**
        Create a new credit type.
        @dev the caller is force to be the credit creator. The initTotalSupply of the credit will be send to the caller.
        @param _initTotalSupply     started balance of the credit
        @param _name                Credit name
        @param _code                Credit code or symbol usaully 3-12 Chars e.g., USD
        @param _issuer              Credit issuer which could be a domain, entity, Stelllar Public key, or Evrynet Public key.
        @param _jsonURL             Credit detail from a REST(GET) API returns JSON
        @param _decimals            Credit decimals
    */
    function create(uint256 _initTotalSupply, string calldata _name, string calldata _code, string calldata _issuer,
                    string calldata _jsonURL, uint16 _decimals) external {
        currentID++;
        totalSupplies[currentID] = _initTotalSupply;
        balances[msg.sender][currentID] = _initTotalSupply;
        creators[currentID] = msg.sender;

        register(currentID, _name, _code, _issuer, _jsonURL, _decimals);

        emit Create(currentID, msg.sender, _initTotalSupply);
    }

    /**
        Generate `_value` of Credit `_id` and transfer to a given `_to`.
        @param _to  Receiver address
        @param _id  Credit type
        @param _value Transfer Credit amount
    */
    function mint(address _to, uint256 _id, uint256 _value) external {
        require(creators[_id] == msg.sender, "Credit: sender is not allowed to mint.");
        require(_to != address(0), "Credit: address zero is not allowed.");
        _isCallable(_to, _id);

        balances[_to][_id].add(_value);
        totalSupplies[_id].add(_value);

        emit Transfer(msg.sender, address(0), _to, _id, _value);
    }

    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
        @param _value Transfer Credit amount
    */
    function burn(uint256 _id, uint256 _value) external {
        balances[msg.sender][_id].sub(_value);
        totalSupplies[_id].sub(_value);

        emit Transfer(msg.sender, msg.sender, address(0), _id, _value);
    }

    /**
        Revoke Credit `_id` creator authorized.
        @param _id  Credit type
    */
    function revokeCreator(uint256 _id) external {
        require(creators[_id] == msg.sender, "Credit; sender is not allowed to revoke the creator");
        creators[_id] = address(0);

        emit RevokeCreator(_id);
    }

    /**
        @notice Get the balance of an account's Credit.
        @param _owner  The address of the token holder
        @param _id     ID of the Credit
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) view external returns(uint256) {
        return balances[_owner][_id];
    }

    /**
        @notice Get the total supply of a Credit.
        @param _id     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _id) view external returns(uint256){
        return totalSupplies[_id];
    }
}
