pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";


contract TestInvalidParameters {
    EER2B private credit;
    string private uri;
    uint256[] private typeIDs;
    uint256[] private values;
    address[] private tos;
    address[] private senders;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    EER2B private proxyCredit;
    bytes private data;
    bool private result;
    uint256 private defaultQuantity = 100;
    uint256 private defaultValue = 1;
    uint256 private expectedQuantityLeft = defaultQuantity - defaultValue;

    // ********************************************* Internal Function *********************************************

    function createFungibleCredit() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, false);
    }

    function createNonFungibleCredit() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, true);
    }

    function setupTest() internal {
        credit = new EER2B();
        uri = "foo";
        result = false;
        data = "data";
        tos = new address[](0);
        senders = new address[](0);
        quantities = new uint256[](0);
        typeIDs = new uint256[](0);
        values = new uint256[](0);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
    }

    function fillUpInvalidParametersLengthParams() internal {
        typeIDs.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(1));
        tos.push(address(2));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(typeIDs[0], senders, quantities);
    }

    function fillUpAddressZeroOnToParams() internal {
        typeIDs.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(0));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(typeIDs[0], senders, quantities);
    }

    function fillUpSenderIsNotAuthorizedParams() internal {
        typeIDs.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(1));
        senders.push(address(2));
        quantities.push(defaultQuantity);
        credit.mintFungible(typeIDs[0], senders, quantities);
    }

    function fillUpToIsContractWithNoTokenReceiverParams() internal {
        typeIDs.push(createFungibleCredit());
        values.push(defaultValue);
        tos.push(address(this));
        senders.push(address(proxyCredit));
        quantities.push(defaultQuantity);
        credit.mintFungible(typeIDs[0], senders, quantities);
    }

    function fillUpSenderIsNotTheOwnerOfCreditParams() internal {
        uint256 _itemID = createNonFungibleCredit() + 1;
        uint256 _typeID = credit.getNonFungibleBaseType(_itemID);
        typeIDs.push(createFungibleCredit());
        typeIDs.push(_typeID);
        values.push(defaultValue);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(typeIDs[0], senders, quantities);
        senders[0] = address(address(2));
        credit.mintNonFungible(_typeID, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpInsufficientAmountParams() internal {
        uint256 _itemID = createNonFungibleCredit() + 1;
        uint256 _typeID = credit.getNonFungibleBaseType(_itemID);
        uint256 overAbundantAmount = defaultQuantity + 1;
        typeIDs.push(_itemID);
        typeIDs.push(createFungibleCredit());
        values.push(1);
        values.push(overAbundantAmount);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(typeIDs[1], senders, quantities);
        credit.mintNonFungible(_typeID, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpNonExistingFungibleCreditParams() internal {
        uint256 _itemID = createNonFungibleCredit() + 1;
        uint256 _typeID = credit.getNonFungibleBaseType(_itemID);
        typeIDs.push(_itemID);
        typeIDs.push(createFungibleCredit());
        values.push(1);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        senders.push(address(proxyCredit));
        credit.mintNonFungible(_typeID, senders);
        senders.push(address(proxyCredit));
    }

    function fillUpNonExistingNonFungibleCreditParams() internal {
        uint256 _itemID = createNonFungibleCredit() + 1;
        typeIDs.push(createFungibleCredit());
        typeIDs.push(_itemID);
        values.push(defaultQuantity);
        values.push(1);
        tos.push(address(1));
        tos.push(address(1));
        quantities.push(defaultQuantity);
        senders.push(address(proxyCredit));
        credit.mintFungible(typeIDs[0], senders, quantities);
        senders.push(address(proxyCredit));
    }

    function executeSafeFullBatchTransferFrom() internal returns (bool _result) {
        proxyCredit.safeFullBatchTransferFrom(senders, tos, typeIDs, values, data);
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
        Assert.isFalse(
            result,
            "should not pass since to is a contract with no token receiver interface"
        );
    }

    // **************** Non-Fungible Case ****************

    function testFungibleWhenSenderIsNotTheOwnerOfCredit() external {
        fillUpSenderIsNotTheOwnerOfCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(
            result,
            "should not pass since to is a contract with no token receiver interface"
        );
    }

    // **************** Fungible Case ********************

    function testFungibleWhenInsufficientAmount() external {
        fillUpInsufficientAmountParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(
            result,
            "should not pass since to is a contract with no token receiver interface"
        );
    }

    function testFungibleWhenCreditIsNotExisted() external {
        fillUpNonExistingFungibleCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(
            result,
            "should not pass since to is a contract with no token receiver interface"
        );
    }

    function testNonFungibleWhenCreditIsNotExisted() external {
        fillUpNonExistingNonFungibleCreditParams();
        result = executeSafeFullBatchTransferFrom();
        Assert.isFalse(
            result,
            "should not pass since to is a contract with no token receiver interface"
        );
    }
}
