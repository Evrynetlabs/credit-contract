pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";
import "../utils/ThrowProxy.sol";

contract TestSafeBatchTransferSuccess {

    ERC1155E private credit;
    string private uri;
    uint256[] private ids;
    uint256[] private values;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    ERC1155E private proxyCredit;
    bytes private data;
    bool result;

    function beforeEach() external {
        credit = new ERC1155E();
        uri = "foo";
        result = false;
        data = "data";
        testAccounts = new address[](0);
        quantities = new uint256[](0);
        ids = new uint256[](0);
        values = new uint256[](0);
        throwProxy = new PayableThrowProxy(address(credit));
        proxyCredit = ERC1155E(address(throwProxy));
        setup();
    }

    function setup() internal {
        uint256 creditType = createNonFungible();
        uint256 id = createFungible();
        ids.push(creditType + 1);
        ids.push(id);
        values.push(1);
        values.push(1);
        testAccounts.push(address(proxyCredit));
        quantities.push(1);
        credit.mintNonFungible(creditType, testAccounts);
        credit.mintFungible(id, testAccounts, quantities);
    }
 
    function createNonFungible() internal returns (uint256 _type) {
        _type =  credit.create(uri, true);
    }

    function createFungible() internal returns (uint256 _id) {
        _id = credit.create(uri, false);
    }

    function testValidParametersWithSenderAsSource() external {
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(1), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(credit.balanceOf(address(1), ids[0]), 1, "balance of non fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(1), ids[0] - 1), 1, "balance of non fungible type of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(1), ids[1]), 1, "balance of fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0]), 0, "balance of non fungible id of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0] - 1), 0, "balance of non fungible type of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[1]), 0, "balance of fungible id of the former balance owner should be 0");
    }

    function testValidParametersWithSenderAsAnOperator() external {
        ThrowProxy transferCaller = new ThrowProxy(address(credit));
        ERC1155E operator = ERC1155E(address(transferCaller));

        proxyCredit.setApprovalForAll(address(operator), true);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "balance owner should successfully approve proxycredit as an operator");
        Assert.isTrue(credit.isApprovedForAll(address(proxyCredit), address(operator)), "proxy credit should be an operator of balance owner");

        operator.safeBatchTransferFrom(address(proxyCredit), address(1), ids, values, data);
        (result, ) = transferCaller.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(credit.balanceOf(address(1), ids[0]), 1, "balance of non fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(1), ids[0] - 1), 1, "balance of non fungible type of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(1), ids[1]), 1, "balance of fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0]), 0, "balance of non fungible id of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0] - 1), 0, "balance of non fungible type of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[1]), 0, "balance of fungible id of the former balance owner should be 0");
    }

    function testWhenDestinationImplementOnERC1155BatchReceived() external {
        PayableThrowProxy destinationProxy = new PayableThrowProxy(address(credit));
        ERC1155E destination = ERC1155E(address(destinationProxy));

        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(destination), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isTrue(result, "should pass since parameters are valid");
        Assert.equal(credit.balanceOf(address(destination), ids[0]), 1, "balance of non fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(destination), ids[0] - 1), 1, "balance of non fungible type of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(destination), ids[1]), 1, "balance of fungible id of address 2 should be 1");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0]), 0, "balance of non fungible id of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[0] - 1), 0, "balance of non fungible type of the former balance owner should be 0");
        Assert.equal(credit.balanceOf(address(proxyCredit), ids[1]), 0, "balance of fungible id of the former balance owner should be 0");
    }
}