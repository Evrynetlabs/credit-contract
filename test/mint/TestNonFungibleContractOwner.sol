pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";
import "../utils/ThrowProxy.sol";

contract TestNonFungibleContractOwner {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenNotImplementOnERC1155Received() external {
        string memory uri = "foo";
        bool isNF = true;
        bool result;
        ThrowProxy throwProxy = new ThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        address[] memory testAccounts = new address[](1);
        testAccounts[0] = address(proxyCredit);
        uint256 _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass since the contract destination doesn't implement onERC1155Received");
    }

    function testWhenImplementOnERC1155Received() external {
        string memory uri = "foo";
        bool isNF = true;
        bool result;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        address[] memory testAccounts = new address[](1);
        testAccounts[0] = address(proxyCredit);
        uint256 _type = credit.create(uri, isNF);
        credit.setMinter(_type, address(proxyCredit));
        proxyCredit.mintNonFungible(_type, testAccounts);
        (result, ) = throwProxy.execute();
        
        Assert.isTrue(result, "should pass since the contract destination implements onERC1155Received");
    }
}
