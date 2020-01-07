pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestSafeBatchTransferError {

    ERC1155e private credit;
    string private uri;
    uint256[] private ids;
    uint256[] private values;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    ERC1155e private proxyCredit;
    bytes private data;
    bool result;

    function beforeEach() external {
      credit = new ERC1155e();
      uri = "foo";
      result = false;
      data = "data";
      testAccounts = new address[](0);
      quantities = new uint256[](0);
      ids = new uint256[](0);
      values = new uint256[](0);
      throwProxy = new PayableThrowProxy(address(credit));
      proxyCredit = ERC1155e(address(throwProxy));
      setup();
    }

    function createNonFungible() internal returns (uint256 _type) {
        _type =  credit.create(uri, true);
    }

    function createFungible() internal returns (uint256 _id) {
        _id = credit.create(uri, false);
    }

    function setup() internal {
        ids.push(createNonFungible());
        ids.push(createFungible());
        values.push(1);
        values.push(1);
        testAccounts.push(address(proxyCredit));
        quantities.push(1);
        credit.mintNonFungible(ids[0], testAccounts);
        credit.mintFungible(ids[1], testAccounts, quantities);
        ids[0] += 1;
    }

    function testTransferToAddressZero() external {
        proxyCredit.safeBatchTransferFrom(address(credit), address(0), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since address is empty(0)");
    }

    function testUnequalIdsAndValuesLength() external {
        values.push(1);
        proxyCredit.safeBatchTransferFrom(address(1), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since tos and values contains unequal length");
    }

    function testWhenMsgSenderIsNotAuthorized() external {
        proxyCredit.safeBatchTransferFrom(address(1), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since message sender is not authorized (neither sender or operator)");
    }
    
    function testInsufficientFungibleCredit() external {
        values[1] = 2;
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(2), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since insufficient amount");
    }

    function testWhenDestinationNotImplementOnERC1155BatchReceived() external {
        proxyCredit.safeBatchTransferFrom(address(proxyCredit), address(this), ids, values, data);
        (result, ) = throwProxy.execute();
        Assert.isFalse(result, "should not pass since the destination does not implement OnERC1155BatchReceived");
    }
}