pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../utils/ThrowProxy.sol";
import "../utils/PayableThrowProxy.sol";
import "../../contracts/ERC1155e.sol";

contract TestOperatorTransferCredit {
    ERC1155E public credit;
    PayableThrowProxy private fooAccountProxy;
    ThrowProxy private operatorAccountProxy;
    address private fooAccount;
    address private operatorAccount;
    uint256 private initialCreditBalance = 100;
    uint256 private transferringAmount = 30;

    function beforeEach() external {
        credit = new ERC1155E();
        fooAccountProxy = new PayableThrowProxy(address(credit));
        fooAccount = address(fooAccountProxy);
        operatorAccountProxy = new ThrowProxy(address(credit));
        operatorAccount = address(operatorAccountProxy);
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
        return nonFungibleCreditType + 1;
    }

    function prepareOperator(bool approved) internal {
        ERC1155E(fooAccount).setApprovalForAll(operatorAccount, approved);
        (bool success, ) = fooAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testTransferFungibleCreditToAccount() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        prepareOperator(true);

        Assert.isTrue(credit.isApprovedForAll(fooAccount, operatorAccount), "operator account does not have the permission");

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, initialCreditBalance, "account should have an initial balance of credit");
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance - transferringAmount, remainingFooAccountBalance, "foo account balance should decreased per transferred amount");
        Assert.equal(initialBarAccountBalance + transferringAmount, remainingBarAccountBalance, "bar account balance should increased per transferred amount");
    }

    function testTransferNonFungibleCreditToAccount() external {
        uint256 nonFungibleCreditID = prepareNonFungible();
        address barAccount = address(1);
        prepareOperator(true);

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 1, "foo account should own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 0, "bar account should not own non-fungible credit");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 0, "foo account should not own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 1, "bar account should own non-fungible credit");
    }

    function testTransferFungibleCreditToTokenReceivedContract() external {
        uint256 fungibleCreditID = prepareFungible();
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);
        prepareOperator(true);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, initialCreditBalance, "account should have an initial balance of credit");
        Assert.equal(initialBarAccountBalance, 0, "account should have no credit balance");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance - transferringAmount, remainingFooAccountBalance, "foo account balance should decreased per transferred amount");
        Assert.equal(initialBarAccountBalance + transferringAmount, remainingBarAccountBalance, "bar account balance should increased per transferred amount");
    }

    function testAuthorizedOperatorTransferNonFungibleCreditToTokenReceivedContract() external {
        uint256 nonFungibleCreditID = prepareNonFungible();
        PayableThrowProxy barAccountProxy = new PayableThrowProxy(address(credit));
        address barAccount = address(barAccountProxy);
        prepareOperator(true);

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 1, "foo account should own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 0, "bar account should not own non-fungible credit");

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isTrue(success, "should not throw error transferring non-fungible credit");

        Assert.equal(credit.balanceOf(fooAccount, nonFungibleCreditID), 0, "foo account should not own non-fungible credit");
        Assert.equal(credit.balanceOf(barAccount, nonFungibleCreditID), 1, "bar account should own non-fungible credit");
    }

    function testErrorTransferFungibleCreditToZeroAddress() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(0);
        prepareOperator(true);

        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        ERC1155E(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute.gas(200000)();
        Assert.isFalse(success, "should throw error transferring to zero address");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }
}