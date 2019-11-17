pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/ThrowProxy.sol";

contract TestFungible {

    function testWhenCreditIsNonFungible() external {
      ERC1155E credit = new ERC1155E();
      string memory uri = "foo";
      bool isNF = true;
      uint256 id = credit.create(uri, isNF);
      bool result;
      address[] memory testAccounts = new address[](1);
      testAccounts[0] = address(1);
      
      credit.mintNonFungible(id, testAccounts);
      ThrowProxy throwProxy = new ThrowProxy(address(credit));
      ERC1155E proxyCredit = ERC1155E(address(throwProxy));

      proxyCredit.burnFungible(id, 1);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since type of credit is non fungible");
    }

    function testWhenQuantityIsSufficient() external {
      ERC1155E credit = new ERC1155E();
      string memory uri = "foo";
      bool isNF = false;
      uint256 id = credit.create(uri, isNF);
      bool result;
      uint256[] memory quantities = new uint256[](1);
      quantities[0] = 1;
      ThrowProxy throwProxy = new ThrowProxy(address(credit));
      ERC1155E proxyCredit = ERC1155E(address(throwProxy)); 
      address[] memory testAccounts = new address[](1);
      testAccounts[0] = address(proxyCredit);
      credit.mintFungible(id, testAccounts, quantities);

      proxyCredit.burnFungible(id, 1);
      (result, ) = throwProxy.execute();
      Assert.isTrue(result, "should pass since credit is fungible");
    }

    function testWhenQuantityIsInSufficient() external {
      ERC1155E credit = new ERC1155E();
      string memory uri = "foo";
      bool isNF = false;
      uint256 id = credit.create(uri, isNF);
      bool result;
      uint256[] memory quantities = new uint256[](1);
      quantities[0] = 1;
      ThrowProxy throwProxy = new ThrowProxy(address(credit));
      ERC1155E proxyCredit = ERC1155E(address(throwProxy)); 
      address[] memory testAccounts = new address[](1);
      testAccounts[0] = address(proxyCredit);  
      credit.mintFungible(id, testAccounts, quantities);

      proxyCredit.burnFungible(id, 2);
      (result, ) = throwProxy.execute();
      Assert.isFalse(result, "should not pass since credit quantity is less than 2");
    }
}
