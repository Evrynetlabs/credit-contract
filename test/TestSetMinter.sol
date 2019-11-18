pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC1155e.sol";
import "./utils/PayableThrowProxy.sol";

contract TestSetMinter {

    ERC1155E private credit;

    function beforeEach() external {
        credit = new ERC1155E();
    }

    function testWhenNewMinterIsCurrentMinter() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.setMinter(id, address(proxyCredit));
        (result, ) = throwProxy.execute();

        Assert.isFalse(result, "Should not pass since a new minter cannot be a current minter (creator by default)");
    }

    function testNewMinter() external {
        string memory uri = "foo";
        bool isNF = false;
        bool result;
        PayableThrowProxy throwProxy = new PayableThrowProxy(address(credit));
        ERC1155E proxyCredit = ERC1155E(address(throwProxy));
        uint256 id = credit.create(uri, isNF);
        credit.setMinter(id, address(proxyCredit));
        proxyCredit.setMinter(id, address(1));
        (result, ) = throwProxy.execute();

        Assert.isTrue(result, "Should pass since a new minter (address 1) is not a current minter (address(proxyCredit))");
        Assert.equal(credit.creators(id), address(1), "should pass since minter has beeen set to address 1");
    }
}
