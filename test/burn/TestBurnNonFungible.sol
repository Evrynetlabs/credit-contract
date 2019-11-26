pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestBurnNonFungible {

    ERC1155e private credit;
    string private uri;
    bool private isNF;
    uint256 private contractType;
    bool private result;
    address[] private testAccounts;
    uint256[] private quantities;
    PayableThrowProxy private throwProxy;
    ERC1155e private proxyCredit;

    function beforeEach() external {
      credit = new ERC1155e();
      uri = "foo";
      isNF = true;
      result = false;
      contractType = credit.create(uri, isNF);
      testAccounts = new address[](0);
      testAccounts.push(address(1));
      quantities = new uint256[](0);
      quantities.push(1);
      throwProxy = new PayableThrowProxy(address(credit));
      proxyCredit = ERC1155e(address(throwProxy));
    }

    function testWhenCreditIsFungible() external {
      isNF = false;
      contractType = credit.create(uri, isNF);
      credit.mintFungible(contractType, testAccounts, quantities);

      proxyCredit.burnNonFungible(contractType);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since the type of credit is fungible");
    }

    function testWhenCallerHasNoPermission() external {
      credit.mintNonFungible(contractType, testAccounts);

      proxyCredit.burnNonFungible(contractType | 1);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since the caller is not the owner of credit id");
    }

    function testWhenSuccess() external {
      testAccounts[0] = address(proxyCredit);
      credit.mintNonFungible(contractType, testAccounts);

      proxyCredit.burnNonFungible(contractType + 1);
      (result, ) = throwProxy.execute();
      Assert.isTrue(result, "should pass since credit is fungible");
      Assert.equal(credit.balanceOf(testAccounts[0], contractType), 0, "the balance of this credit id/type after being burned should be 0");
      Assert.equal(credit.balanceOf(testAccounts[0], contractType + 1), 0, "the balance of this credit id/type after being burned should be 0");
    }
}
