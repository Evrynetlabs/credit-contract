pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";
import "../utils/ThrowProxy.sol";

contract TestFungibleContractOwner {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenNotImplementOnERC1155Received() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        ThrowProxy throwProxy = new ThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        address[] memory testAccounts = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = address(proxyCredit);
        quantities[0] = 1;
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass since the contract destination doesn't implement onERC1155Received");
    }

    function testWhenImplementOnERC1155Received() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        address[] memory testAccounts = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = address(proxyCredit);
        quantities[0] = 1;
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();
        
        Assert.isTrue(result, "should pass since the contract destination implements onERC1155Received");
    }
}
