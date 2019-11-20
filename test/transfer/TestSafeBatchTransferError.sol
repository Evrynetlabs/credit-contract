pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestSafeBatchTransferError {

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
    }

    function createNonFungible() public returns (uint256 _type) {
        _type =  credit.create(uri, true);
    }

    function createFungible() public returns (uint256 _id) {
        _id = credit.create(uri, false);
    }

    function testEmptyDestinationAddress() external {
        proxyCredit.safeBatchTransferFrom(address(credit), address(0x0), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since address is empty(0x0)");
    }

    function testUnequalTosAndValuesLength() external {
        proxyCredit.safeBatchTransferFrom(address(1), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since tos and values contains unequal length");
    }

    function testWhenSourceAddressIsInvalid() external {
        proxyCredit.safeBatchTransferFrom(address(1), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since from(source) address is not the msg.sender");
    }
    
    function testInsufficientFungibleCredit() external {
        ids.push(this.createFungible());
        values.push(1);
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since insufficient amount");
    }

    function testInsufficientNonFungibleCredit() external {
        ids.push(this.createNonFungible());
        values.push(1);
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since insufficient amount");
    }

    function testWhenDestinationNotImplementOnERC1155BatchReceived() external {
        PayableThrowProxy balanceOwnerCaller = new PayableThrowProxy(address(credit));
        ERC1155E balanceOwner = ERC1155E(address(balanceOwnerCaller));
        ids.push(this.createNonFungible());
        ids.push(this.createFungible());
        values.push(1);
        values.push(1);
        testAccounts.push(address(balanceOwner));
        quantities.push(1);
        credit.mintNonFungible(ids[0], testAccounts);
        credit.mintFungible(ids[1], testAccounts, quantities);

        balanceOwner.setApprovalForAll(address(proxyCredit), true);
        (result, ) = balanceOwnerCaller.execute();
        Assert.isTrue(result, "balance owner should successfully approve proxycredit as an operator");

        ids[0] += 1;
        proxyCredit.safeBatchTransferFrom(address(balanceOwner), address(this), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since the destination does not implement OnERC1155BatchReceived");
    }
}