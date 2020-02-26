pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/EER2B.sol";
import "../utils/PayableThrowProxy.sol";
import "../utils/ThrowProxy.sol";


contract TestSafeBatchTransferSuccess {
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

    function setup() internal {
        uint256 creditType = createNonFungible();
        uint256 typeID = createFungible();
        typeIDs.push(creditType + 1);
        typeIDs.push(typeID);
        values.push(1);
        values.push(1);
        testAccounts.push(address(proxyCredit));
        quantities.push(1);
        credit.mintNonFungible(creditType, testAccounts);
        credit.mintFungible(typeID, testAccounts, quantities);
    }

    function createNonFungible() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, true);
    }

    function createFungible() internal returns (uint256 _typeID) {
        _typeID = credit.create(uri, false);
    }

    function testValidParametersWithSenderAsSource() external {
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(1), typeIDs, values, data);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[0]),
            1,
            "balance of non fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[0] - 1),
            1,
            "balance of non fungible type of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[1]),
            1,
            "balance of fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0]),
            0,
            "balance of non fungible id of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0] - 1),
            0,
            "balance of non fungible type of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[1]),
            0,
            "balance of fungible id of the former balance owner should be 0"
        );
    }

    function testValidParametersWithSenderAsAnOperator() external {
        ThrowProxy transferCaller = new ThrowProxy(address(credit));
        EER2B operator = EER2B(address(transferCaller));

        proxyCredit.setApprovalForAll(address(operator), true);
        (result, ) = throwProxy.execute();
        Assert.isTrue(
            result,
            "balance owner should successfully approve proxycredit as an operator"
        );
        Assert.isTrue(
            credit.isApprovedForAll(address(proxyCredit), address(operator)),
            "proxy credit should be an operator of balance owner"
        );

        operator.safeBatchTransferFrom(address(proxyCredit), address(1), typeIDs, values, data);
        (result, ) = transferCaller.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[0]),
            1,
            "balance of non fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[0] - 1),
            1,
            "balance of non fungible type of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(1), typeIDs[1]),
            1,
            "balance of fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0]),
            0,
            "balance of non fungible id of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0] - 1),
            0,
            "balance of non fungible type of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[1]),
            0,
            "balance of fungible id of the former balance owner should be 0"
        );
    }

    function testWhenDestinationImplementOnEER2BatchReceived() external {
        PayableThrowProxy destinationProxy = new PayableThrowProxy(address(credit));
        EER2B destination = EER2B(address(destinationProxy));

        proxyCredit.safeBatchTransferFrom(
            address(proxyCredit),
            address(destination),
            typeIDs,
            values,
            data
        );
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(
            credit.balanceOf(address(destination), typeIDs[0]),
            1,
            "balance of non fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(destination), typeIDs[0] - 1),
            1,
            "balance of non fungible type of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(destination), typeIDs[1]),
            1,
            "balance of fungible id of address 2 should be 1"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0]),
            0,
            "balance of non fungible id of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[0] - 1),
            0,
            "balance of non fungible type of the former balance owner should be 0"
        );
        Assert.equal(
            credit.balanceOf(address(proxyCredit), typeIDs[1]),
            0,
            "balance of fungible id of the former balance owner should be 0"
        );
    }
}
