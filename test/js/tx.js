// node test/js/sighash.js --require PATH_TO_BSV
const path = require('path')
const i = process.argv.indexOf('--require')
const bsv = require(process.argv[i+1])
const Input = require( path.join(process.argv[i+1], 'lib/transaction/input/publickeyhash.js') )

const wif = "L3a9qdwKdCiem4XJ5QrdFGWRE19h6k44P8RSGFyjW5b5q7vNZMy1"
const addr = "15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf"

const privKey = bsv.PrivateKey.fromWIF(wif)

const prevTx = new bsv.Transaction()
prevTx.to(addr, 10000)

const utxo = new Input({
  prevTxId: prevTx.hash,
  output: prevTx.outputs[0],
  outputIndex: 0,
  script: null
})

const script = new bsv.Script()
script.add( bsv.Opcode.OP_FALSE )
script.add( bsv.Opcode.OP_RETURN )
script.add( Buffer.from("hello world") )

const output = new bsv.Transaction.Output({
  satoshis: 0,
  script: script
})

const tx = new bsv.Transaction()
tx.addInput(utxo)
tx.addOutput(output)
tx.change(addr)
tx.sign(privKey)

console.log(tx.hash)
console.log(tx.outputs[1].satoshis)

tx.fee(1000)
tx.sign(privKey)

console.log(tx.hash)
console.log(tx.outputs[1].satoshis)
