pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../../contracts/ERC1155e.sol";
import "../utils/PayableThrowProxy.sol";

contract TestFungubleCreditLength {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenTosAndQuantititesLengthAreUnequal() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        address[] memory testAccounts = new address[](2);
        uint256[] memory quantities = new uint256[](1);
        testAccounts[0] = address(1);
        testAccounts[1] = address(2);
        quantities[0] = 1;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.mintFungible(id, testAccounts, quantities);
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "should not pass length comparison");
    }
}
