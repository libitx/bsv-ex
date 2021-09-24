defmodule BSV.BlockHeader do
  @moduledoc """
  TODO
  """
  alias BSV.Serializable
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct [:version, :prev_hash, :merkle_root, :time, :bits, :nonce]

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    prev_hash: <<_::256>>,
    merkle_root: <<_::256>>,
    time: non_neg_integer(),
    bits: non_neg_integer(),
    nonce: non_neg_integer()
  }

  @doc """
  TODO
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, header, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, header}
    end
  end

  @doc """
  TODO
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, header} ->
        header

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = header, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    header
    |> Serializable.serialize()
    |> encode(encoding)
  end


  defimpl Serializable do
    @impl true
    def parse(header, data) do
      with <<
            version::little-32,
            prev_hash::binary-size(32),
            merkle_root::binary-size(32),
            time::little-32,
            bits::little-32,
            nonce::little-32,
            rest::binary
          >> <- data
      do
        {:ok, struct(header, [
          version: version,
          prev_hash: prev_hash,
          merkle_root: merkle_root,
          time: time,
          bits: bits,
          nonce: nonce
        ]), rest}
      end
    end

    @impl true
    def serialize(%{
      version: version,
      prev_hash: prev_hash,
      merkle_root: merkle_root,
      time: time,
      bits: bits,
      nonce: nonce
    }) do
      <<
        version::little-32,
        prev_hash::binary,
        merkle_root::binary,
        time::little-32,
        bits::little-32,
        nonce::little-32
      >>
    end
  end

end
