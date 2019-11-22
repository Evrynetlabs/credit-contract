pragma solidity ^0.5.0;

import "truffle/Assert.sol";
import "../utils/ThrowProxy.sol";
import "../utils/PayableThrowProxy.sol";
import "../../contracts/ERC1155e.sol";

contract TestErrorTransferCredit {
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
        (bool success, ) = fooAccountProxy.execute();
        Assert.isTrue(success, "should not throw error setting approval to operator");
    }

    function testErrorTransferCreditToZeroAddress() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(0);
        prepareOperator(true);

        ERC1155e(fooAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error owner transfers to zero address");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error operator transfers to zero address");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialCreditBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(0, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorUnauthorizedOperator() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        prepareOperator(false);

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, transferringAmount, bytes(""));
        (bool success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error no transfer permission");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialCreditBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(0, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorTransferNonFungibleCreditWithoutOwnership() external {
        uint256 nonFungibleCreditType = prepareNonFungible();
        uint256 nonFungibleCreditID = nonFungibleCreditType + 2;
        address barAccount = address(1);
        prepareOperator(true);

        uint256 initialFooAccountTypeBalance = credit.balanceOf(fooAccount, nonFungibleCreditType);
        uint256 initialBarAccountTypeBalance = credit.balanceOf(barAccount, nonFungibleCreditType);
        uint256 initialFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 initialBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        ERC1155e(fooAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error transfer without ownership");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barAccount, nonFungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error transfer without ownership via operator");

        uint256 remainingFooAccountTypeBalance = credit.balanceOf(fooAccount, nonFungibleCreditType);
        uint256 remainingBarAccountTypeBalance = credit.balanceOf(barAccount, nonFungibleCreditType);
        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, nonFungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, nonFungibleCreditID);

        Assert.equal(initialFooAccountTypeBalance, remainingFooAccountTypeBalance, "balance of non fungible credit type of the foo account should not decreased");
        Assert.equal(initialBarAccountTypeBalance, remainingBarAccountTypeBalance, "balance of non fungible credit type of the bar account should not increased");
        Assert.equal(initialFooAccountBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(initialBarAccountBalance, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorTransferCreditToNotSupportedContract() external {
        uint256 fungibleCreditID = prepareFungible();
        address barContract = address(new ThrowProxy(address(1)));
        prepareOperator(true);

        ERC1155e(fooAccount).safeTransferFrom(fooAccount, barContract, fungibleCreditID, 1, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error owner transfers to not supported contract");

        ERC1155e(operatorAccount).safeTransferFrom(fooAccount, barContract, fungibleCreditID, 1, bytes(""));
        (success, ) = operatorAccountProxy.execute();
        Assert.isFalse(success, "should throw error operator transfers to not supported contract");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barContract, fungibleCreditID);

        Assert.equal(initialCreditBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(0, remainingBarAccountBalance, "bar account balance should not increased");
    }

    function testErrorTransferCreditInsufficientAmount() external {
        uint256 fungibleCreditID = prepareFungible();
        address barAccount = address(1);
        uint256 overTransferringAmount = 120;

        ERC1155e(fooAccount).safeTransferFrom(fooAccount, barAccount, fungibleCreditID, overTransferringAmount, bytes(""));
        (bool success, ) = fooAccountProxy.execute();
        Assert.isFalse(success, "should throw error insufficient amount to transfer fungible credit");

        uint256 remainingFooAccountBalance = credit.balanceOf(fooAccount, fungibleCreditID);
        uint256 remainingBarAccountBalance = credit.balanceOf(barAccount, fungibleCreditID);

        Assert.equal(initialCreditBalance, remainingFooAccountBalance, "foo account balance should not decreased");
        Assert.equal(0, remainingBarAccountBalance, "bar account balance should not increased");
    }
}