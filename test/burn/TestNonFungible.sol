pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestFungible {

    ERC1155E private credit;
    string private uri;
    bool private isNF;
    uint256 private _type;
    bool private result;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    ERC1155E private proxyCredit;

    function beforeEach() external {
      credit = new ERC1155E();
      uri = "foo";
      isNF = true;
      result = false;
      _type = credit.create(uri, isNF);
      testAccounts = new address[](0);
      testAccounts.push(address(1));
      quantities = new uint256[](0);
      quantities.push(1);
      throwProxy = new PayableThrowProxy(address(credit));
      proxyCredit = ERC1155E(address(throwProxy));
    }

    function testWhenCreditIsNonFungible() external {
      isNF = false;
      _type = credit.create(uri, isNF);
      credit.mintFungible(_type, testAccounts, quantities);

      proxyCredit.burnNonFungible(_type);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since type of credit is non fungible");
    }

    function testQuantities() external {
      credit.mintNonFungible(_type, testAccounts);

      proxyCredit.burnNonFungible(_type);
      (result, ) = throwProxy.execute();
      Assert.equal(credit.balanceOf(testAccounts[0], _type), 0, "credit after being burned should be 0");
      Assert.isTrue(result, "should pass since credit is fungible");

      proxyCredit.burnNonFungible(_type);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since credit quantity is less than 1");
    }
}
