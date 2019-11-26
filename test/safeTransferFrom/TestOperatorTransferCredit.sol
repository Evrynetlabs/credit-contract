pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../utils/ThrowProxy.sol";
import "../utils/PayableThrowProxy.sol";
import "../../contracts/ERC1155e.sol";

contract TestOperatorTransferCredit {
    ERC1155e public credit;
    PayableThrowProxy private fooAccountProxy;
    ThrowProxy private operatorAccountProxy;
    address private fooAccount;
    address private operatorAccount;
    uint256 private initialCreditBalance = 100;
    uint256 private transferringAmount = 30;

    function beforeEach() external {
        credit = new ERC1155e();
        fooAccountProxy = new PayableThrowProxy(address(credit));
        fooAccount = address(fooAccountProxy);
        operatorAccountProxy = new ThrowProxy(address(credit));
        operatorAccount = address(operatorAccountProxy);
        prepareOperator(true);
    }

    function prepareFungible() internal returns(uint256) {
        uint256 fungibleCreditID = credit.create("", false);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;
        uint256[] memory quantities = new uint256[](1);
        quantities[0] = initialCreditBalance;

        credit.mintFungible(fungibleCreditID, tos, quantities);
        return fungibleCreditID;
    }

    function prepareNonFungible() internal returns(uint256){
        uint256 nonFungibleCreditType = credit.create("", true);

        address[] memory tos = new address[](1);
        tos[0] = fooAccount;

        credit.mintNonFungible(nonFungibleCreditType, tos);
        return nonFungibleCreditType;
    }

    function prepareOperator(bool approved) internal {
        ERC1155e(fooAccount).setApprovalForAll(operatorAccount, approved);
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testTransferFungibleCreditToAccount() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);

        Assert.isTrue(credit.isApprovedForAll(fooAccount, operatorAccount), "operator account does not have the permission");

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, initialCreditBalance, "account should have an initial balance of credit");
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance - transferringAmount, remainingFooAccountBalance, "foo account balance should decreased per transferred amount");
        Assert.equal(initialBarAccountBalance + transferringAmount, remainingBarAccountBalance, "bar account balance should increased per transferred amount");
    }

    function testTransferNonFungibleCreditToAccount() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 1;
        address barAccount = address(1);

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditType), 1, "balance of non fungible credit type of the foo account should be 1");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditType), 0, "balance of non fungible credit type of the bar account should be 0");
        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 1, "foo account should own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 0, "bar account should not own non-fungible credit");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditType), 0, "balance of non fungible credit type of the foo account should be 0");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditType), 1, "balance of non fungible credit type of the bar account should be 1");
        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 0, "foo account should not own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 1, "bar account should own non-fungible credit");
    }

    function testTransferFungibleCreditToTokenReceivedContract() external {
        uint256 fungibleCreditID = prepareFungible();
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, initialCreditBalance, "account should have an initial balance of credit");
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance - transferringAmount, remainingFooAccountBalance, "foo account balance should decreased per transferred amount");
        Assert.equal(initialBarAccountBalance + transferringAmount, remainingBarAccountBalance, "bar account balance should increased per transferred amount");
    }

    function testAuthorizedOperatorTransferNonFungibleCreditToTokenReceivedContract() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 1;
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditType), 1, "balance of non fungible credit type of the foo account should be 1");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditType), 0, "balance of non fungible credit type of the bar account should be 0");
        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 1, "foo account should own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 0, "bar account should not own non-fungible credit");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditType), 0, "balance of non fungible credit type of the foo account should be 0");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditType), 1, "balance of non fungible credit type of the bar account should be 1");
        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 0, "foo account should not own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 1, "bar account should own non-fungible credit");
    }
}