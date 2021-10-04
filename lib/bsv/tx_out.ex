defmodule BSV.TxOut do
  @moduledoc """
  TODO
  """
  alias BSV.{Script, Serializable, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct satoshis: 0, script: %Script{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    satoshis: non_neg_integer(),
    script: Script.t()
  }

  @doc """
  TODO
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
  TODO
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
  TODO
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{} = txout),
    do: to_binary(txout) |> byte_size()

  @doc """
  TODO
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
