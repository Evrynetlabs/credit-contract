pragma solidity >=0.4.25 <0.6.0;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/ERC1155e.sol";

contract TestCreateCredit {

    Credit private credit;
    address private testAccount;

    function beforeAll() external {
      credit = new Credit();
      testAccount = address(0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c);
    }

    function testCreateANewCredit() external {
        Assert.equal(credit.getCurrentID(), 0, "initial credit id should be zero");

        uint expectedInitialSupply = 100000;
        string memory expectedName = "name";
        string memory expectedCode = "code";
        string memory expectedIssuer = "issuer";
        string memory expectedJson = "json";
        uint16 expectedDecimals = 10;

        credit.create(expectedInitialSupply, expectedName, expectedCode, expectedIssuer, expectedJson, expectedDecimals);

        uint id = credit.getCurrentID();

        Assert.equal(id, 1, "first credit id should be one");
        Assert.equal(credit.totalSupply(id), expectedInitialSupply, "the credit totalSupply is incorrect");
        Assert.equal(credit.name(id), expectedName, "the credit name is incorrect");
        Assert.equal(credit.code(id), expectedCode, "the credit code is incorrect");
        Assert.equal(credit.issuer(id), expectedIssuer, "the credit issuer is incorrect");
        Assert.equal(credit.jsonURL(id), expectedJson, "the credit jsonURL is incorrect");
        Assert.equal(uint(credit.decimals(id)), uint(expectedDecimals), "the credit decimals is incorrect");

    }

    function testMint() external {
        uint expectedValue = 100000;
        uint id = credit.getCurrentID();
        Assert.equal(id, 1, "initial credit id should be zero");
        credit.mint(testAccount, id, expectedValue);
        Assert.equal(credit.balanceOf(testAccount, id), expectedValue, "minting function is failed");
    }

    function testBurn() external {
        uint expectedValue = 100000;
        uint id = credit.getCurrentID();
        Assert.equal(id, 1, "initial credit id should be zero");
        credit.burn(id, expectedValue);
        Assert.equal(credit.balanceOf(tx.origin, id), 0, "minting function is failed");
    }

}
