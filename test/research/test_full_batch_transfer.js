const ERC1155e = artifacts.require('ERC1155e');
const truffleAssert = require('truffle-assertions')
const MAXIMUM_ARRAY_SIZE = 1
const web3 = require('web3')


contract('ERC1155e', accounts => {
    describe('call full batch transaction', () => {
        it('should accept a huge amount of credit', async () => {
            const instance = await ERC1155e.deployed()
            const baseAccounts = await new Array(MAXIMUM_ARRAY_SIZE).fill(accounts[0])
            const destinations = await new Array(MAXIMUM_ARRAY_SIZE).fill(accounts[1])
            const ids = await Promise.all(new Array(MAXIMUM_ARRAY_SIZE).fill(instance.create.call('foo', false)))
            const values = new Array(MAXIMUM_ARRAY_SIZE).fill(web3.utils.toBN(0))
            const tx = await instance.safeFullBatchTransferFrom(baseAccounts, destinations, ids, values , web3.utils.fromAscii('test'))
            console.log(tx)
            console.log(web3.utils.fromAscii('test'))
            truffleAssert.eventEmitted(tx, 'TransferFullBatch', (ev) => {
                return ev._memo === web3.utils.fromAscii('test')
            }, 'TransferFullBatch should be emitted with corrected parameters');
        })
    })
})





