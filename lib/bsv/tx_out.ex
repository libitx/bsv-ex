defmodule BSV.TxOut do
  @moduledoc """
  A TxOut is a data structure representing a single output in a `t:BSV.Tx.t/0`.

  A TxOut consists of the number of satoshis being locked in the output, and a
  `t:BSV.Script.t/0`, otherwise known as the locking script. The output can
  later be spent by creating an input in a new transaction with a corresponding
  unlocking script.

  The index of the output within it's containing `t:BSV.Tx.t/0`, denotes it's
  `t:BSV.TxOut.vout/0`.
  """
  alias BSV.{Script, Serializable, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct satoshis: 0, script: %Script{}

  @typedoc "TxOut struct"
  @type t() :: %__MODULE__{
    satoshis: non_neg_integer(),
    script: Script.t()
  }

  @typedoc """
  Vout - Vector of an output in a Bitcoin transaction

  In integer representing the index of a TxOut.
  """
  @type vout() :: non_neg_integer()

  @doc """
  Parses the given binary into a `t:BSV.TxOut.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, txout, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, txout}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.TxOut.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, txout} ->
        txout

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Returns the number of bytes of the given `t:BSV.TxOut.t/0`.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{} = txout),
    do: to_binary(txout) |> byte_size()

  @doc """
  Serialises the given `t:BSV.TxOut.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = txout, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    txout
    |> Serializable.serialize()
    |> encode(encoding)
  end


  defimpl Serializable do
    @impl true
    def parse(txout, data) do
      with <<satoshis::little-64, data::binary>> <- data,
           {:ok, script, rest} <- VarInt.parse_data(data),
           {:ok, script} <- Script.from_binary(script)
      do
        {:ok, struct(txout, [
          satoshis: satoshis,
          script: script
        ]), rest}
      end
    end

    @impl true
    def serialize(%{satoshis: satoshis, script: script}) do
      script_data = script
      |> Script.to_binary()
      |> VarInt.encode_binary()

      <<
        satoshis::little-64,
        script_data::binary
      >>
    end
  end
end
