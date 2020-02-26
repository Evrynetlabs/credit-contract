pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";


contract TestSafeBatchTransferError {
    EER2B private credit;
    string private uri;
    uint256[] private typeIDs;
    uint256[] private values;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    EER2B private proxyCredit;
    bytes private data;
    bool result;

    function beforeEach() external {
        credit = new EER2B();
        uri = "foo";
        result = false;
        data = "data";
        testAccounts = new address[](0);
        quantities = new uint256[](0);
        typeIDs = new uint256[](0);
        values = new uint256[](0);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = EER2B(address(throwProxy));
        setup();
    }

    function createNonFungible() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, true);
    }

    function createFungible() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, false);
    }

    function setup() internal {
        typeIDs.push(createNonFungible());
        typeIDs.push(createFungible());
        values.push(1);
        values.push(1);
        testAccounts.push(address(proxyCredit));
        quantities.push(1);
        credit.mintNonFungible(typeIDs[0], testAccounts);
        credit.mintFungible(typeIDs[1], testAccounts, quantities);
        typeIDs[0] += 1;
    }

    function testTransferToAddressZero() external {
        proxyCredit.safeBatchTransferFrom(address(credit), address(0), typeIDs, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since address is empty(0)");
    }

    function testUnequalIdsAndValuesLength() external {
        values.push(1);
        proxyCredit.safeBatchTransferFrom(address(1), address(2), typeIDs, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since tos and values contains unequal length");
    }

    function testWhenMsgSenderIsNotAuthorized() external {
        proxyCredit.safeBatchTransferFrom(address(1), address(2), typeIDs, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(
            result,
            "should not pass since message sender is not authorized (neither sender or operator)"
        );
    }

    function testInsufficientFungibleCredit() external {
        values[1] = 2;
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(2), typeIDs, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since insufficient amount");
    }

    function testWhenDestinationNotImplementOnEER2BatchReceived() external {
        proxyCredit.safeBatchTransferFrom(
            address(proxyCredit),
            address(this),
            typeIDs,
            values,
            data
        );
        (result, ) = throwProxy.execute();
        Assert.isFalse(
            result,
            "should not pass since the destination does not implement OnEER2BatchReceived"
        );
    }
}
