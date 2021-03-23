defmodule BSV.Transaction.Signature do
  @moduledoc """
  Module for signing transactions.
  """

  use Bitwise
  alias BSV.Crypto.{Hash, Secp256k1}
  alias BSV.Script
  alias BSV.Transaction
  alias BSV.Transaction.{Input, Output}
  alias BSV.Util
  alias BSV.Util.VarBin

  @sighash_all 0x01
  @sighash_none 0x02
  @sighash_single 0x03
  @sighash_forkid 0x40
  @sighash_anyonecanpay 0x80

  @default_sighash @sighash_all ||| @sighash_forkid

  defguard sighash_all?(sighash_type)
    when (sighash_type &&& 31) == @sighash_all

  defguard sighash_none?(sighash_type)
    when (sighash_type &&& 31) == @sighash_none

  defguard sighash_single?(sighash_type)
    when (sighash_type &&& 31) == @sighash_single

  defguard sighash_forkid?(sighash_type)
    when (sighash_type &&& @sighash_forkid) != 0

  defguard sighash_anyone_can_pay?(sighash_type)
    when (sighash_type &&& @sighash_anyonecanpay) != 0


  @doc """
  Signs the given transaction input with the given private key.

  ## Options

  The accepted options are:

  * `:sighash_type` - Optionally specify the sighash type by passing an 8-bit integer. Defaults to `SIGHASH_FORKID`.
  """
  @spec sign_input(Transaction.t, integer, binary, keyword) :: {binary, integer}
  def sign_input(%Transaction{} = tx, vin, <<private_key::binary>>, options \\ []) do
    sighash_type = Keyword.get(options, :sighash_type, @default_sighash)

    signature = tx
    |> sighash(vin, sighash_type)
    |> Secp256k1.sign(private_key)
    {signature, sighash_type}
  end


  @doc """
  Generates a transaction digest for signing, using the given sighash type.
  """
  @spec sighash(Transaction.t, integer, integer) :: binary
  def sighash(%Transaction{} = tx, vin, sighash_type) do
    tx
    |> preimage(vin, sighash_type)
    |> Hash.sha256_sha256
  end


  @doc """
  Generates a transaction preimage, suing the given sighash type
  """
  @spec preimage(Transaction.t, integer, integer) :: binary
  def preimage(%Transaction{} = tx, index, sighash_type)
    when sighash_forkid?(sighash_type)
  do
    input = Enum.at(tx.inputs, index)

    # Input prevouts/nSequence
    hash_prevouts = get_prevouts_hash(tx.inputs, sighash_type)
    hash_sequence = get_sequence_hash(tx.inputs, sighash_type)

    # outpoint (32-byte hash + 4-byte little endian)
    outpoint = input.output_txid
    |> Util.decode(:hex)
    |> Util.reverse_bin
    |> Kernel.<>(<<input.output_index::little-32>>)

    # script of the input
    subscript = input.utxo.script
    |> Script.serialize
    |> VarBin.serialize_bin

    # Outputs (none/one/all, depending on flags)
    hash_outputs = get_outputs_hash(tx.outputs, index, sighash_type)

    <<
      tx.version::little-32,
      hash_prevouts::binary,
      hash_sequence::binary,
      outpoint::binary,
      subscript::binary,
      input.utxo.satoshis::little-64,
      input.sequence::little-32,
      hash_outputs::binary,
      tx.lock_time::little-32,
      (sighash_type >>> 0)::little-32
    >>
  end

  def preimage(%Transaction{} = _tx, %Input{} = _input, _sighash_type),
    do: raise "Legacy Sighash algorithm not implemented yet."


  defp get_prevouts_hash(_inputs, sighash_type)
    when sighash_anyone_can_pay?(sighash_type),
    do: :binary.copy(<<0>>, 32)

  defp get_prevouts_hash(inputs, _sighash_type) do
    inputs
    |> Enum.reduce(<<>>, &get_prevouts/2)
    |> Hash.sha256_sha256
  end

  defp get_prevouts(input, bin) do
    txid = input.output_txid
    |> Util.decode(:hex)
    |> Util.reverse_bin
    bin <> <<txid::binary, input.output_index::little-32>>
  end

  defp get_sequence_hash(_inputs, sighash_type)
    when sighash_anyone_can_pay?(sighash_type)
    or sighash_single?(sighash_type)
    or sighash_none?(sighash_type),
    do: :binary.copy(<<0>>, 32)

  defp get_sequence_hash(inputs, _sighash_type) do
    inputs
    |> Enum.reduce(<<>>, &get_sequence/2)
    |> Hash.sha256_sha256
  end

  defp get_sequence(input, bin),
    do: bin <> <<input.sequence::little-32>>

  defp get_outputs_hash(outputs, index, sighash_type)
    when sighash_single?(sighash_type)
    and index < length(outputs)
  do
    outputs
    |> Enum.at(index)
    |> Output.serialize
    |> Hash.sha256_sha256
  end

  defp get_outputs_hash(outputs, _index, sighash_type)
    when not sighash_none?(sighash_type)
  do
    outputs
    |> Enum.reduce(<<>>, &get_output/2)
    |> Hash.sha256_sha256
  end

  defp get_outputs_hash(_outputs, _index, _sighash_type),
    do: :binary.copy(<<0>>, 32)

  defp get_output(output, bin),
    do: bin <> Output.serialize(output)

end
