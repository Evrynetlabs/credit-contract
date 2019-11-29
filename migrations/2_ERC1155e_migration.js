const ERC1155e = artifacts.require('ERC1155e')

module.exports = async function (deployer) {
  await deployer.deploy(ERC1155e)
}
