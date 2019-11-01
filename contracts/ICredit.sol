pragma solidity ^0.5.0;

import "./IMetadata.sol";

interface ICredit {
    
    event Transfer(address indexed _sender, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event BatchTransfer(address indexed _sender, address indexed _from, address indexed _to, uint256[] _ids, uint256[]
                        _values);
    event FullBatchTransfer(address indexed _sender, address[] indexed _froms, address[] indexed _tos, uint256[] _ids,
                            uint256[] _values);
    event ApproveForAll(address indexed _customer, address indexed _broker);
    event ApproveForEach(address indexed _customer, address indexed _broker, uint256 indexed _id);
    event Create(uint256 indexed _id, address _creator, uint256 _initTotalSupply);
    event RevokeCreator(uint256 indexed _id);

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
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) external;

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
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values) external;

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
    function safeFullBatchTransfer(address[] calldata _from, address[] calldata _to, uint256[] calldata _ids, uint256[]
                                   calldata _values) external;

    /**
        Set a full authorized of a broker over a customer portfolio.
        @param _broker      Broker address
        @param _isApproved  true if give a full access to the broker. Otherwise, false
    */
    function setApproveForAll(address _broker, bool _isApproved) external;

    /**
        Set an individual credit type authorized of a broker over a customer portfolio.
        @param _broker      Broker address
        @param _id          credit type id which the broker can control
        @param _isApproved  true if give a full access to the broker. Otherwise, false
    */
    function setApproveForEach(address _broker, uint256 _id, bool _isApproved) external;

    /**
        @notice Get a broker authorized status over a customer portfolio.
        @param _customer    Credit owner
        @param _broker      Broker address
        @param _id          credit type id which the broker can control
        @return broker status
    */
    function getApprove(address _customer, address _broker, uint256 _id) view external returns(bool);

    /**
        Create a new credit type.
        @dev the caller is force to be the credit creator. The initTotalSupply of the credit will be send to the caller.
        @param _initTotalSupply     started balance of the credit
    */
    function create(uint256 _initTotalSupply) external;

    /**
        Generate `_value` of Credit `_id` and transfer to a given `_to`.
        @param _to  Receiver address
        @param _id  Credit type
        @param _value Transfer Credit amount
    */
    function mint(address _to, uint256 _id, uint256 _value) external;
    
    /**
        Delete `_value` of Credit `_id` from the world.
        @param _id  Credit type
        @param _value Transfer Credit amount
    */
    function burn(uint256 _id, uint256 _value) external;
    
    /**
        Revoke Credit `_id` creator authorized.
        @param _id  Credit type
    */
    function revokeCreator(uint256 _id) external;

    /**
        @notice Get the balance of an account's Credit.
        @param _owner  The address of the token holder
        @param _id     ID of the Credit
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) view external returns(uint256);

    /**
        @notice Get the total supply of a Credit.
        @param _id     ID of the Credit
        @return        The total supply of the Token type requested
     */
    function totalSupply(uint256 _id) view external returns(uint256);
}

