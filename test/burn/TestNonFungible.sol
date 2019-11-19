pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestNonFungible {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenCreditIsFungible() external {
      string memory uri = "foo";
      bool isNF = false;
      uint256 _type = credit.create(uri, isNF);
      bool result;
      address[] memory testAccounts = new address[](1);
      testAccounts[0] = address(1);
      uint256[] memory quantities = new uint256[](1);
      quantities[0] = 1;

      credit.mintFungible(_type, testAccounts, quantities);
      PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
      ERC1155E proxyCredit = ERC1155E(address(throwProxy));

      proxyCredit.burnNonFungible(_type + 1);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since type of credit is fungible");
    }

    function testWhenCreditIsNonFungible() external {
      string memory uri = "foo";
      bool isNF = true;
      bool result;
      uint256 _type = credit.create(uri, isNF);

      PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
      ERC1155E proxyCredit = ERC1155E(address(throwProxy));
      address[] memory testAccounts = new address[](1);
      testAccounts[0] = address(throwProxy);
      credit.mintNonFungible(_type, testAccounts);
      
      proxyCredit.burnNonFungible(_type + 1);
      (result, ) = throwProxy.execute();
      Assert.isTrue(result, "should pass since credit is non fungible");

      proxyCredit.burnNonFungible(_type + 1);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since balance of type will be less than 0");
    }
}
