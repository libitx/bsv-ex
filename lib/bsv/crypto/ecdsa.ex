defmodule BSV.Crypto.ECDSA do
  @moduledoc """
  Functions for use with ECDSA asymmetric cryptography.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.generate_key_pair
      ...>
      ...> message = "hello world"
      ...> signature = BSV.Crypto.ECDSA.sign(message, ecdsa_key.private_key)
      ...> BSV.Crypto.ECDSA.verify(message, signature, ecdsa_key.public_key)
      true
  """
  alias BSV.Util
  alias BSV.Crypto.ECDSA.Key

  @named_curve :secp256k1


  @doc """
  Generate a new ECDSA keypair.

  ## Options

  The accepted options are:

  * `:named_curve` - Specify the elliptic curve name. Defaults to `:secp256k1`.

  """
  @spec generate_key_pair(list) :: Key.t
  def generate_key_pair(options \\ []) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    :public_key.generate_key({:namedCurve, named_curve})
    |> Key.from_sequence
  end


  @doc """
  Creates a signature for the given message, using the given private key.

  ## Options

  The accepted options are:

  * `:named_curve` - Specific the elliptic curve name. Defaults to `:secp256k1`.
  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Crypto.ECDSA.sign("hello world", private_key, encode: :base64)
      << signature >>
  """
  @spec sign(binary, Key.t | binary, list) :: binary
  def sign(message, private_key, options \\ [])

  def sign(message, ecdsa_key = %Key{}, options) do
    encoding = Keyword.get(options, :encode)
    :public_key.sign(message, :sha256, Key.as_sequence(ecdsa_key))
    |> Util.encode(encoding)
  end

  def sign(message, private_key, options) when is_binary(private_key) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    encoding = Keyword.get(options, :encode)
    :crypto.sign(:ecdsa, :sha256, message, [private_key, named_curve])
    |> Util.encode(encoding)
  end


  @doc """
  Verify the given message and signature, using the given private key.

  ## Options

  The accepted options are:

  * `:named_curve` - Specific the elliptic curve name. Defaults to `:secp256k1`.

  ## Examples
  
      BSV.Crypto.RSA.verify(signature, public_key)
  """
  @spec verify(binary, Key.t | binary, list) :: boolean
  def verify(message, signature, public_key, options \\ [])

  def verify(message, signature, ecdsa_key = %Key{}, options) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    :public_key.verify(message, :sha256, signature, {Key.get_point(ecdsa_key), {:namedCurve, named_curve}})
  end

  def verify(message, signature, public_key, options) when is_binary(public_key) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, named_curve])
  end


  @doc """
  Decodes the given PEM string into a ECDSA key.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> pem = BSV.Crypto.ECDSA.pem_encode(ecdsa_key)
      ...>
      ...> imported_key = BSV.Crypto.ECDSA.pem_decode(pem)
      ...> imported_key == ecdsa_key
      true
  """
  @spec pem_decode(binary) :: Key.t
  def pem_decode(pem) do
    :public_key.pem_decode(pem)
    |> List.first
    |> :public_key.pem_entry_decode
    |> Key.from_sequence
  end


  @doc """
  Encodes the given public or private key into a PEM string.

  ## Examples

      iex> BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.pem_encode
      ...> |> String.starts_with?("-----BEGIN EC PRIVATE KEY-----")
      true
  """
  @spec pem_encode(Key.t) :: binary
  def pem_encode(ecdsa_key = %Key{}) do
    pem_entry = :public_key.pem_entry_encode(:ECPrivateKey, Key.as_sequence(ecdsa_key))
    :public_key.pem_encode([pem_entry])
  end
  
end