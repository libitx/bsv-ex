defmodule BSV.Transaction do
  @moduledoc """
  Module for the construction, parsing and serialization of Bitcoin transactions.
  """
  alias BSV.Crypto.{Hash, ECDSA}
  alias BSV.Address
  alias BSV.KeyPair
  alias BSV.Extended.PrivateKey
  alias BSV.Script.PublicKeyHash
  alias BSV.Transaction.{Input, Output, Signature}
  alias BSV.Util
  alias BSV.Util.VarBin

  defstruct version: 1,
            lock_time: 0,
            inputs: [],
            outputs: [],
            change_script: nil,
            change_index: nil,
            fee: nil

  @typedoc "Bitcoin Transaction"
  @type t :: %__MODULE__{
    version: integer,
    lock_time: integer,
    inputs: list,
    outputs: list,
    change_script: nil,
    change_index: nil,
    fee: nil
  }

  @dust_limit 546
  @fee_per_kb 500


  @doc """
  Parse the given binary into a transaction. Returns a tuple containing the
  transaction input and the remaining binary data.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.parse(data)
      {%BSV.Trasaction{}, ""}
  """
  @spec parse(binary, keyword) :: {__MODULE__.t, binary}
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<version::little-32, data::binary>> = data |> Util.decode(encoding)
    {inputs, data} = data |> VarBin.parse_items(&Input.parse/1)
    {outputs, data} = data |> VarBin.parse_items(&Output.parse/1)
    <<lock_time::little-32, data::binary>> = data

    {struct(__MODULE__, [
      version: version,
      inputs: inputs,
      outputs: outputs,
      lock_time: lock_time
    ]), data}
  end


  @doc """
  Serialises the given transaction into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Transaction.Input.serialize(input)
      <<binary>>
  """
  @spec serialize(__MODULE__.t, keyword) :: binary
  def serialize(%__MODULE__{} = tx, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    inputs = tx.inputs |> VarBin.serialize_items(&Input.serialize/1)
    outputs = tx.outputs |> VarBin.serialize_items(&Output.serialize/1)
    <<
      tx.version::little-32,
      inputs::binary,
      outputs::binary,
      tx.lock_time::little-32
    >>
    |> Util.encode(encoding)
  end


  @doc """
  Returns the given transaction's txid, which is a double SHA-256 hash of the
  serialized transaction, reversed.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_to("1B8j21Ym6QbJQ6kRvT1N7pvdBN2qPDhqij", 72000)
      ...> |> BSV.Transaction.get_txid
      "c8e8f4951eb08f9e6e12b92da30b0b9a0849202dcbb5ac35e13acc91b8c4de6d"
  """
  @spec get_txid(__MODULE__.t) :: String.t
  def get_txid(%__MODULE__{} = tx) do
    serialize(tx)
    |> Hash.sha256_sha256
    |> Util.reverse_bin
    |> Util.encode(:hex)
  end


  @doc """
  Returns the size of the given transaction. Where any inputs are without a
  signed script, it's size is estimated assuming a P2PKH input.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_from(%BSV.Transaction.Input{utxo: %BSV.Transaction.Output{satoshis: 100000}})
      ...> |> BSV.Transaction.spend_to("1B8j21Ym6QbJQ6kRvT1N7pvdBN2qPDhqij", 75000)
      ...> |> BSV.Transaction.get_size
      192
  """
  @spec get_size(__MODULE__.t) :: integer
  def get_size(%__MODULE__{} = tx) do
    inputs = tx.inputs
    |> Enum.map(&Input.get_size/1)
    |> Enum.sum
    |> Kernel.+(tx.inputs |> length |> VarBin.serialize_int |> byte_size)
    outputs = tx.outputs
    |> Enum.map(&Output.get_size/1)
    |> Enum.sum
    |> Kernel.+(tx.outputs |> length |> VarBin.serialize_int |> byte_size)

    8 + inputs + outputs
  end


  @doc """
  Returns the fee for the given transaction. If the fee has already been set
  using `f:BSV.Transaction.set_fee/2`, then that figure is returned. Otherwise
  a fee is calculated based on the result of `f:BSV.Transaction.get_size/1`.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.set_fee(500)
      ...> |> BSV.Transaction.get_fee
      500

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_from(%BSV.Transaction.Input{utxo: %BSV.Transaction.Output{satoshis: 100000}})
      ...> |> BSV.Transaction.spend_to("1B8j21Ym6QbJQ6kRvT1N7pvdBN2qPDhqij", 75000)
      ...> |> BSV.Transaction.get_fee
      96
  """
  @spec get_fee(__MODULE__.t) :: integer
  def get_fee(%__MODULE__{fee: fee}) when is_integer(fee),
    do: fee

  def get_fee(%__MODULE__{fee: fee} = tx) when is_nil(fee),
    do: get_size(tx) * @fee_per_kb / 1000 |> round


  @doc """
  Sets the fee for the given transaction. Resets the signatures for all inputs.
  """
  @spec set_fee(__MODULE__.t, integer) :: __MODULE__.t
  def set_fee(%__MODULE__{} = tx, fee) when is_integer(fee) do
    Map.put(tx, :fee, fee)
    |> update_change_output
  end


  @doc """
  Returns the change output of the given transaction.
  """
  @spec get_change_output(__MODULE__.t) :: Output.t
  def get_change_output(%__MODULE__{change_index: index})
    when is_nil(index),
    do: nil

  def get_change_output(%__MODULE__{} = tx) do
    Enum.at(tx.outputs, tx.change_index)
  end


  @doc """
  Returns the sum from all inputs of the given transaction.

  ## Examples

      iex> inputs = [
      ...>   %BSV.Transaction.Input{utxo: %BSV.Transaction.Output{satoshis: 1575}},
      ...>   %BSV.Transaction.Input{utxo: %BSV.Transaction.Output{satoshis: 3000}}
      ...> ]
      ...>
      iex> BSV.Transaction.spend_from(%BSV.Transaction{}, inputs)
      ...> |> BSV.Transaction.get_input_sum
      4575
  """
  @spec get_input_sum(__MODULE__.t) :: integer
  def get_input_sum(%__MODULE__{} = tx),
    do: tx.inputs |> Enum.reduce(0, &(&2 + &1.utxo.satoshis))


  @doc """
  Returns the sum from all outputs of the given transaction.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 5000)
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 1325)
      ...> |> BSV.Transaction.get_output_sum
      6325
  """
  @spec get_output_sum(__MODULE__.t) :: integer
  def get_output_sum(%__MODULE__{} = tx),
    do: tx.outputs |> Enum.reduce(0, &(&2 + &1.satoshis))


  @doc """
  Adds the given input to the transaction. Resets the signatures for all inputs.

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.add_input(%BSV.Transaction.Input{})
      iex> length(tx.inputs) == 1
      true
  """
  @spec add_input(__MODULE__.t, Input.t) :: __MODULE__.t
  def add_input(%__MODULE__{} = tx, %Input{} = input) do
    inputs = Enum.concat(tx.inputs, [input])
    Map.put(tx, :inputs, inputs)
    |> update_change_output
  end


  @doc """
  Adds the given output to the transaction. Resets the signatures for all inputs.

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.add_output(%BSV.Transaction.Output{})
      iex> length(tx.outputs) == 1
      true
  """
  @spec add_output(__MODULE__.t, Output.t) :: __MODULE__.t
  def add_output(%__MODULE__{} = tx, %Output{} = output) do
    outputs = Enum.concat(tx.outputs, [output])
    Map.put(tx, :outputs, outputs)
    |> update_change_output
  end


  @doc """
  Adds the given input or list of inputs to the transaction. Each input must be
  complete with a spendable UTXO or the function will raise an error. Resets the
  signatures for all inputs.
  """
  @spec spend_from(__MODULE__.t, Input.t | list) :: __MODULE__.t
  def spend_from(%__MODULE__{}, %Input{utxo: utxo})
    when is_nil(utxo),
    do: raise "Invalid input. Must have spendable UTXO."

  def spend_from(%__MODULE__{} = tx, %Input{} = input) do
    case Enum.member?(tx.inputs, input) do
      true -> tx
      false -> add_input(tx, input)
    end
  end

  def spend_from(%__MODULE__{} = tx, inputs) when is_list(inputs),
    do: inputs |> Enum.reduce(tx, &(spend_from(&2, &1)))


  @doc """
  Creates a P2PKH output using the given address and spend amount, and adds the
  output to the transaction. Resets the signatures for all inputs.

  ## Examples

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 1000)
      iex> length(tx.outputs) == 1
      true
  """
  @spec spend_to(__MODULE__.t, Address.t | binary, integer) :: __MODULE__.t
  def spend_to(%__MODULE__{} = tx, address, satoshis) do
    output = struct(Output, [
      satoshis: satoshis,
      script: PublicKeyHash.build_output_script(address)
    ])
    add_output(tx, output)
  end


  @doc """
  Specifies the change address for the given transaction. Resets the signatures
  for all inputs.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_from(%BSV.Transaction.Input{utxo: %BSV.Transaction.Output{satoshis: 100000}})
      ...> |> BSV.Transaction.spend_to("1B8j21Ym6QbJQ6kRvT1N7pvdBN2qPDhqij", 75000)
      ...> |> BSV.Transaction.change_to("1G26ZnsXQpL9cdqCKE6vViMdW9QwRQTcTJ")
      ...> |> BSV.Transaction.get_change_output
      %BSV.Transaction.Output{
        satoshis: 24887,
        script: %BSV.Script{
          chunks: [
            :OP_DUP,
            :OP_HASH160,
            <<164, 190, 242, 205, 108, 224, 228, 253, 144, 102, 35, 209, 230, 33, 135, 143, 211, 21, 79, 82>>,
            :OP_EQUALVERIFY,
            :OP_CHECKSIG
          ]
        }
      }
  """
  @spec change_to(__MODULE__.t, Address.t | binary) :: __MODULE__.t
  def change_to(%__MODULE__{} = tx, address) do
    script = PublicKeyHash.build_output_script(address)
    Map.put(tx, :change_script, script)
    |> update_change_output
  end


  @doc """
  Signs the transaction using the given private key or list of keys. Each input
  is iterrated over verifying that the key can sign the input.
  """
  @spec sign(
    __MODULE__.t,
    KeyPair.t | PrivateKey.t | {binary, binary} | binary | list
  ) :: __MODULE__.t
  def sign(%__MODULE__{} = tx, %KeyPair{} = key),
    do: sign(tx, {key.public_key, key.private_key})

  def sign(%__MODULE__{} = tx, %PrivateKey{} = private_key) do
    public_key = PrivateKey.get_public_key(private_key)
    sign(tx, {public_key.key, private_key.key})
  end

  def sign(%__MODULE__{} = tx, private_key) when is_binary(private_key) do
    keypair = private_key
    |> ECDSA.generate_key_pair
    |> KeyPair.from_ecdsa_key
    sign(tx, keypair)
  end

  def sign(%__MODULE__{} = tx, {public_key, private_key}) do
    pubkey_hash = Address.from_public_key(public_key)
    |> Map.get(:hash)

    inputs = Enum.map(tx.inputs, fn input ->
      case pubkey_hash == PublicKeyHash.get_hash(input.utxo.script) do
        false -> input
        true ->
          script = tx
          |> Signature.sign_input(input, private_key)
          |> PublicKeyHash.build_input_script(public_key)
          Map.put(input, :script, script)
      end
    end)
    Map.put(tx, :inputs, inputs)
  end

  def sign(%__MODULE__{} = tx, keys) when is_list(keys),
    do: keys |> Enum.reduce(tx, &(sign(&2, &1)))

  @spec is_coinbase(__MODULE__.t()) :: boolean
  def is_coinbase(%__MODULE__{inputs: [first_input | _] = inputs}), do:
    length(inputs) == 1 and Input.is_null(first_input)

  # Needs to be called every time a change is made to inputs or outputs
  defp update_change_output(%__MODULE__{change_script: script} = tx)
    when is_nil(script),
    do: tx

  defp update_change_output(%__MODULE__{} = tx) do
    tx = tx
    |> remove_change_output
    |> clear_signatures
    |> add_change_output

    change_amount = get_input_sum(tx) - get_output_sum(tx) - get_fee(tx)

    case change_amount > @dust_limit do
      false -> remove_change_output(tx)
      true ->
        tx
        |> remove_change_output
        |> add_change_output(change_amount)
    end
  end


  defp remove_change_output(%__MODULE__{change_index: index} = tx)
    when is_nil(index),
    do: tx

  defp remove_change_output(%__MODULE__{change_index: index} = tx) do
    outputs = List.delete_at(tx.outputs, index)
    tx
    |> Map.put(:outputs, outputs)
    |> Map.put(:change_index, nil)
  end


  defp add_change_output(%__MODULE__{} = tx, satoshis \\ 0) do
    index   = length(tx.outputs)
    output  = struct(Output, script: tx.change_script, satoshis: satoshis)
    outputs = tx.outputs ++ [output]
    tx
    |> Map.put(:outputs, outputs)
    |> Map.put(:change_index, index)
  end


  defp clear_signatures(%__MODULE__{} = tx) do
    inputs = tx.inputs
    |> Enum.map(&(Map.put(&1, :script, nil)))
    Map.put(tx, :inputs, inputs)
  end

end
