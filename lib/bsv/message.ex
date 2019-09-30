defmodule BSV.Message do
  @moduledoc """
  Module to sign and verify messages with Bitcoin keys. Is compatible with
  ElectrumSV and bsv.js.
  
  Internally uses `libsecp256k1` NIF bindings for compact signatures and public
  key recovery from signatures.
  """
  alias BSV.Crypto.Hash
  alias BSV.Wallet.KeyPair
  alias BSV.Util
  alias BSV.Util.VarBin

  
  @doc """
  Creates a signature for the given message, using the given private key.

  ## Options

  The accepted options are:

  * `:encoding` - Encode the returned binary with either the `:base64` (default) or `:hex` encoding scheme. Set to `false` to return binary signature.

  ## Examples

      BSV.Message.sign("hello world", private_key)
      "Hw9bs6VZ..."
  """
  @spec sign(binary, KeyPair.t | binary, keyword) :: binary
  def sign(message, private_key, options \\ [])

  def sign(message, %KeyPair{} = key, options) do
    compressed = case byte_size(key.public_key) do
      33 -> true
      _ -> false
    end
    options = Keyword.put(options, :compressed, compressed)
    sign(message, key.private_key, options)
  end

  def sign(message, private_key, options) when is_binary(private_key) do
    compressed = Keyword.get(options, :compressed, true)
    encoding = Keyword.get(options, :encoding, :base64)

    {:ok, signature, recovery} = message
    |> message_digest
    |> :libsecp256k1.ecdsa_sign_compact(private_key, :default, <<>>)

    <<sig_prefix(compressed) + recovery, signature::binary>>
    |> Util.encode(encoding)
  end


  @doc """
  Verify the given message and signature, using the given Bitcoin address or
  public key.

  ## Options

  The accepted options are:

  * `:encoding` - Decode the given signature with either the `:base64` (default) or `:hex` encoding scheme. Set to `false` to accept binary signature.

  ## Examples
  
      BSV.Crypto.RSA.verify(signature, message, address)
      true
  """
  @spec verify(binary, binary, KeyPair.t | binary, keyword) :: boolean
  def verify(signature, message, public_key, options \\[])

  def verify(signature, message, %KeyPair{} = key, options) do
    verify(signature, message, key.public_key, options)
  end

  def verify(signature, message, public_key, options) when is_binary(public_key) do
    encoding = Keyword.get(options, :encoding, :base64)

    <<prefix::integer, sig::binary>> = Util.decode(signature, encoding)
    {comp, comp_opt} = if prefix > 30, do: {true, :compressed}, else: {false, :uncompressed}

    with true <- String.valid?(public_key),
         {:ok, public_key} <- message_digest(message)
          |> :libsecp256k1.ecdsa_recover_compact(sig, comp_opt, prefix - sig_prefix(comp))
    do
      do_verify(sig, message, public_key)
    else
      false -> do_verify(sig, message, public_key)
      {:error, err} -> raise inspect(err)
    end
  end


  defp do_verify(signature, message, public_key) do

    case message_digest(message)
      |> :libsecp256k1.ecdsa_verify_compact(signature, public_key)
    do
      :ok -> true
      _err -> false
    end
  end


  defp message_digest(message) do
    prefix = "Bitcoin Signed Message:\n"
    b1 = prefix |> byte_size |> VarBin.serialize_int
    b2 = message |> byte_size |> VarBin.serialize_int
    <<b1::binary, prefix::binary, b2::binary, message::binary>>
    |> Hash.sha256_sha256
  end

  defp sig_prefix(true), do: 31
  defp sig_prefix(false), do: 27
  
end