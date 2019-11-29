pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestInvalidParameters {

    ERC1155e private credit;
    string private uri;
    uint256[] private ids;
    uint256[] private values;
    address[] private tos;
    address[] private senders;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    ERC1155e private proxyCredit;
    bytes private data;
    bool private result;
    uint256 private defaultQuantity = 100;
    uint256 private defaultValue = 1;
    uint256 private expectedQuantityLeft = defaultQuantity - defaultValue;

    // ********************************************* Internal Function *********************************************

    function createFungibleCredit() internal returns (uint256 _id) {
        _id = credit.create(uri, false);
    }

    function createNonFungibleCredit() internal returns (uint256 _type) {
        _type = credit.create(uri, true);
    }

    function setupTest() internal {
        credit = new ERC1155e();
        uri = "foo";
        result = false;
        data = "data";
        tos = new address[](0);
        senders = new address[](0);
        quantities = new uint256[](0);
        ids = new uint256[](0);
        values = new uint256[](0);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = ERC1155e(address(throwProxy));
    }

    function fillUpInvalidParametersLengthParams() internal {
        ids.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(1));
        tos.push(address(2));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(ids[0], senders, quantities);
    }

    function fillUpAddressZeroOnToParams() internal {
        ids.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(0));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(ids[0], senders, quantities);
    }

    function fillUpSenderIsNotAuthorizedParams() internal {
        ids.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(1));
        senders.push(address(2));
        quantities.push(defaultQuantity);
        credit.mintFungible(ids[0], senders, quantities);
    }

    function fillUpToIsContractWithNoTokenReceiverParams() internal {
        ids.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(this));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(ids[0], senders, quantities);
    }

    function fillUpSenderIsNotTheOwnerOfCreditParams() internal {
        uint256 _id = createNonFungibleCredit() + 1;
        uint256 _type = credit.getNonFungibleBaseType(_id);
        ids.push(createFungibleCredit());
        ids.push(_id);
        values.push(defaultValue);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(ids[0], senders, quantities);
        senders[0] = address(address(2));
        credit.mintNonFungible(_type, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpInsufficientAmountParams() internal {
        uint256 _id = createNonFungibleCredit() + 1;
        uint256 _type = credit.getNonFungibleBaseType(_id);
        uint256 overAbundantAmount = defaultQuantity + 1;
        ids.push(_id);
        ids.push(createFungibleCredit());
        values.push(1);
        values.push(overAbundantAmount);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(ids[1], senders, quantities);
        credit.mintNonFungible(_type, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpNonExistingFungibleCreditParams() internal {
        uint256 _id = createNonFungibleCredit() + 1;
        uint256 _type = credit.getNonFungibleBaseType(_id);
        ids.push(_id);
        ids.push(createFungibleCredit());
        values.push(1);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        senders.push(address(proxyCredit));
        credit.mintNonFungible(_type, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpNonExistingNonFungibleCreditParams() internal {
        uint256 _id = createNonFungibleCredit() + 1;
        ids.push(createFungibleCredit());
        ids.push(_id);
        values.push(defaultQuantity);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(ids[0], senders, quantities);
        senders.push(address(proxyCredit));
    }

    function executeSafeFullBatchTransferFrom() internal returns (bool _result) {
        proxyCredit.safeFullBatchTransferFrom(senders, tos, ids, values, data);
        (_result, ) = throwProxy.execute();
    }

    // ********************************************* External Function *********************************************
    
    function beforeEach() external {
        setupTest();
    }

    // **************** Common Case ****************

    function testInvalidParametersLength() external {
        fillUpInvalidParametersLengthParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since parameters contain invalid length");
    }

    function testTransferToAddressZero() external {
        fillUpAddressZeroOnToParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since address is empty(0)");
    }

    function testWhenSenderIsNotAuthorized() external {
        fillUpSenderIsNotAuthorizedParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since sender is unauthorized");
    }

    function testWhenToIsContractWithNoTokenReceiverInterface() external {
        fillUpToIsContractWithNoTokenReceiverParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since to is a contract with no token receiver interface");
    }

    // **************** Non-Fungible Case ****************

    function testFungibleWhenSenderIsNotTheOwnerOfCredit() external {
        fillUpSenderIsNotTheOwnerOfCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since to is a contract with no token receiver interface");
    }

    // **************** Fungible Case ********************

    function testFungibleWhenInsufficientAmount() external {
        fillUpInsufficientAmountParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since to is a contract with no token receiver interface");
    }

    function testFungibleWhenCreditIsNotExisted() external {
        fillUpNonExistingFungibleCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since to is a contract with no token receiver interface");
    }

    function testNonFungibleWhenCreditIsNotExisted() external {
        fillUpNonExistingNonFungibleCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(result, "should not pass since to is a contract with no token receiver interface");
    }
}