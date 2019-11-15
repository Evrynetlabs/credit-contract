pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "./utils/ThrowProxy.sol";
import "../contracts/ERC1155e.sol";

contract ERC1155EWrapper is ERC1155E {
    constructor() public ERC1155E(){}

    function callBalanceOfBatch(address[] calldata _owners, uint256[] calldata _ids, uint256[] calldata _expecteds) external {
        Assert.equal(this.balanceOfBatch(_owners, _ids), _expecteds, "balances are invalid");
    }
}

contract TestOwnership {

    ERC1155EWrapper private credit;
    ThrowProxy private throwProxy;
    uint256 private fungibleCreditID;
    uint256 private nonFungibleCreditID;
    uint256 private notExistingCreditID = 1000;
    uint256 private expectedBalance = 100;
    address private fooAccount = address(1);
    address private barAccount = address(2);

    function beforeEach() external {
        credit = new ERC1155EWrapper();
        throwProxy = new ThrowProxy(address(credit));
        fungibleCreditID = credit.create("", false);
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;
        uint256[] memory quantities = new uint256[](1);
        quantities[0] = expectedBalance;

        credit.mintFungible(fungibleCreditID, tos, quantities);
        credit.mintNonFungible(nonFungibleCreditType, tos);
        nonFungibleCreditID = nonFungibleCreditType + 1;
    }

    function testBalanceOf() external {
        Assert.equal(credit.balanceOf(fooAccount, fungibleCreditID), expectedBalance,
            "account should have an expected credit balance");
        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 1, "account should own a credit");
        Assert.equal(credit.balanceOf(barAccount, fungibleCreditID), 0, "account should not have a credit balance");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 0, "account should not own a credit");
        Assert.equal(credit.balanceOf(fooAccount, notExistingCreditID), 0, "account should not have a credit balance");
    }

    function testBalanceOfBatch() external {
        address[] memory owners = new address[](5);
        owners[0] = fooAccount;
        owners[1] = fooAccount;
        owners[2] = barAccount;
        owners[3] = barAccount;
        owners[4] = fooAccount;

        uint256[] memory ids = new uint256[](5);
        ids[0] = fungibleCreditID;
        ids[1] = nonFungibleCreditID;
        ids[2] = fungibleCreditID;
        ids[3] = nonFungibleCreditID;
        ids[4] = notExistingCreditID;

        uint256[] memory expecteds = new uint256[](5);
        expecteds[0] = expectedBalance;
        expecteds[1] = 1;
        expecteds[2] = 0;
        expecteds[3] = 0;
        expecteds[4] = 0;

        ERC1155EWrapper(address(throwProxy)).callBalanceOfBatch(owners, ids, expecteds);
        (bool success, ) = throwProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error");
    }

    function testErrorBalanceOfBatch() external {
        address[] memory owners = new address[](2);
        owners[0] = fooAccount;
        owners[1] = barAccount;

        uint256[] memory ids = new uint256[](3);
        ids[0] = fungibleCreditID;
        ids[1] = nonFungibleCreditID;
        ids[2] = fungibleCreditID;

        uint256[] memory expecteds = new uint256[](3);

        ERC1155EWrapper(address(throwProxy)).callBalanceOfBatch(owners, ids, expecteds);
        (bool success, ) = throwProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error");
    }

    function testOwnerOf() external {
        Assert.equal(credit.ownerOf(nonFungibleCreditID), fooAccount, "fooAccount should be an owner of the non-fungible credit ID");
        Assert.equal(credit.ownerOf(fungibleCreditID), address(0), "should return address 0 when it is fungible credit ID");
        Assert.equal(credit.ownerOf(notExistingCreditID), address(0), "should return address 0 when the credit is not existing");
    }
}