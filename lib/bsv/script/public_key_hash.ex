defmodule BSV.Script.PublicKeyHash do
  @moduledoc """
  Module for building P2PKH input and output scripts.
  """
  alias BSV.Address
  alias BSV.Script


  @doc """
  Build a new P2PKH input script, from the given signature and public key.
  """
  @spec build_input_script({binary, integer}, binary) :: Script.t
  def build_input_script({<<signature::binary>>, sigtype}, <<public_key::binary>>)
    when is_integer(sigtype)
  do
    struct(Script, chunks: [
      <<signature::binary, sigtype::integer>>,
      public_key
    ])
  end


  @doc """
  Build a new P2PKH output script, from the given address or public key.

  ## Examples

      iex> BSV.KeyPair.from_ecdsa_key(BSV.Test.bsv_keys)
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Script.PublicKeyHash.build_output_script
      %BSV.Script{
        chunks: [
          :OP_DUP,
          :OP_HASH160,
          <<47, 105, 50, 137, 102, 179, 60, 141, 131, 76, 2, 71, 24, 254, 231, 1, 101, 139, 55, 71>>,
          :OP_EQUALVERIFY,
          :OP_CHECKSIG
        ]
      }
  """
  @spec build_output_script(Address.t | binary) :: Script.t
  def build_output_script(%Address{} = address) do
    chunks = [
      :OP_DUP,
      :OP_HASH160,
      address.hash,
      :OP_EQUALVERIFY,
      :OP_CHECKSIG
    ]
    struct(Script, chunks: chunks)
  end

  def build_output_script(public_key) when is_binary(public_key) do
    case String.valid?(public_key) do
      true -> Address.from_string(public_key)
      false -> Address.from_public_key(public_key)
    end
    |> build_output_script
  end


  @doc """
  Returns the public key hash from the given P2PKH output script.
  """
  @spec get_hash(Script.t) :: binary
  def get_hash(%Script{} = script), do: Enum.at(script.chunks, 2)
  
end