defmodule BSV.KeyPair do
  @moduledoc """
  TODO
  """
  alias BSV.{PrivKey, PubKey}

  defstruct privkey: nil, pubkey: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    privkey: PrivKey.t(),
    pubkey: PubKey.t()
  }

  @doc """
  TODO
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {_pubkey, privkey} = :crypto.generate_key(:ecdh, :secp256k1)
    privkey
    |> PrivKey.from_binary!(opts)
    |> from_privkey()
  end

  @doc """
  TODO
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{} = privkey) do
    struct(__MODULE__, [
      privkey: privkey,
      pubkey: PubKey.from_privkey(privkey)
    ])
  end

end
