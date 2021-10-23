defmodule BSV.KeyPair do
  @moduledoc """
  A keypair is a data structure consisting of both a `t:BSV.PrivKey.t/0` and its
  corresponding `t:BSV.PubKey.t/0`.
  """
  alias BSV.{PrivKey, PubKey}

  defstruct privkey: nil, pubkey: nil

  @typedoc "KeyPair struct"
  @type t() :: %__MODULE__{
    privkey: PrivKey.t(),
    pubkey: PubKey.t()
  }

  @doc """
  Generates and returns a new `t:BSV.KeyPair.t/0`.
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {_pubkey, privkey} = :crypto.generate_key(:ecdh, :secp256k1)
    privkey
    |> PrivKey.from_binary!(opts)
    |> from_privkey()
  end

  @doc """
  Returns a `t:BSV.KeyPair.t/0` from the given `t:BSV.PrivKey.t/0`.
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{} = privkey) do
    struct(__MODULE__, [
      privkey: privkey,
      pubkey: PubKey.from_privkey(privkey)
    ])
  end

end
