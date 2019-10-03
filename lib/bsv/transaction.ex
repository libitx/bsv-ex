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

  defstruct version: 1, inputs: [], outputs: [], lock_time: 0

  @typedoc "Bitcoin Transaction"
  @type t :: %__MODULE__{
    version: integer,
    inputs: list,
    outputs: list,
    lock_time: integer
  }

  
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
  """
  @spec get_txid(__MODULE__.t) :: String.t
  def get_txid(%__MODULE__{} = tx) do
    serialize(tx)
    |> Hash.sha256_sha256
    |> Util.reverse_bin
    |> Util.encode(:hex)
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
      ...> |> BSV.Transaction.input_sum
      4575
  """
  @spec input_sum(__MODULE__.t) :: integer
  def input_sum(%__MODULE__{} = tx),
    do: tx.inputs |> Enum.reduce(0, &(&2 + &1.utxo.satoshis))


  @doc """
  Returns the sum from all outputs of the given transaction.

  ## Examples

      iex> %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 5000)
      ...> |> BSV.Transaction.spend_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf", 1325)
      ...> |> BSV.Transaction.output_sum
      6325
  """
  @spec output_sum(__MODULE__.t) :: integer
  def output_sum(%__MODULE__{} = tx),
    do: tx.outputs |> Enum.reduce(0, &(&2 + &1.satoshis))


  @doc """
  Adds the given input to the transaction. The input must be complete with a
  UTXO or the function will raise an error.

  ## Examples

      iex> input = %BSV.Transaction.Input{utxo: %BSV.Transaction.Output{}}
      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.add_input(input)
      iex> length(tx.inputs) == 1
      true
  """
  @spec add_input(__MODULE__.t, Input.t) :: __MODULE__.t
  def add_input(%__MODULE__{}, %Input{utxo: utxo})
    when is_nil(utxo),
    do: raise "Invalid input. Must have UTXO."

  def add_input(%__MODULE__{} = tx, %Input{} = input) do
    inputs = Enum.concat(tx.inputs, [input])
    Map.put(tx, :inputs, inputs)
  end


  @doc """
  Adds the given output to the transaction.

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
  end


  @doc """
  Adds the given input or list of inputs to the transaction.
  """
  @spec spend_from(__MODULE__.t, Input.t | list) :: __MODULE__.t
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
  output to the transaction.

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

end