// node test/js/sighash.js --require PATH_TO_BSV
const path = require('path')
const i = process.argv.indexOf('--require')
const bsv = require(process.argv[i+1])
const Input = require( path.join(process.argv[i+1], 'lib/transaction/input/publickeyhash.js') )

const wif = "L3a9qdwKdCiem4XJ5QrdFGWRE19h6k44P8RSGFyjW5b5q7vNZMy1"
const addr = "15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf"

const privKey = bsv.PrivateKey.fromWIF(wif)

const prevTx = new bsv.Transaction()
prevTx.to(addr, 50000)

const utxo = new Input({
  prevTxId: prevTx.hash,
  output: prevTx.outputs[0],
  outputIndex: 0,
  script: null
})

const tx = new bsv.Transaction()
tx.addInput(utxo)

const sh = bsv.Transaction.Sighash.sighash(tx, (0x01 | 0x40), 0, utxo.output.script, utxo.output.satoshisBN)
const sig = bsv.Transaction.Sighash.sign(tx, privKey, (0x01 | 0x40), 0, utxo.output.script, utxo.output.satoshisBN)

console.log('sighash', sh.toString('hex'))
console.log('sig', sig.toString('hex'))