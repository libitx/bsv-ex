defmodule BSV.Crypto.ECDSA do
  @moduledoc """
  Functions for use with ECDSA asymmetric cryptography.

  ## Examples

      iex> private_key = BSV.Crypto.ECDSA.generate_key
      ...> public_key = BSV.Crypto.ECDSA.PrivateKey.get_public_key(private_key)
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.ECDSA.sign(private_key)
      ...> |> BSV.Crypto.ECDSA.verify("hello world", public_key)
      true
  """
  alias BSV.Util
  alias BSV.Crypto.ECDSA.PublicKey
  alias BSV.Crypto.ECDSA.PrivateKey

  @named_curve :secp256k1


  @doc """
  Generates a new ECDSA private key.

  ## Options

  The accepted options are:

  * `:named_curve` - Specify the elliptic curve name. Defaults to `:secp256k1`.

  ## Examples

      iex> private_key = BSV.Crypto.ECDSA.generate_key
      ...> private_key.__struct__ == BSV.Crypto.ECDSA.PrivateKey
      true
  """
  @spec generate_key(keyword) :: PrivateKey.t
  def generate_key(options \\ []) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    :public_key.generate_key({:namedCurve, named_curve})
    |> PrivateKey.from_sequence
  end


  @doc """
  Generates a new ECDSA public and private key pair, returned as a tuple containing two binaries.

  ## Options

  The accepted options are:

  * `:named_curve` - Specify the elliptic curve name. Defaults to `:secp256k1`.
  * `:private_key` - When a private key binary is given, it will be returned with its public key.

  ## Examples

      iex> BSV.Crypto.ECDSA.generate_key_pair
      ...> |> is_tuple
      true

      iex> ecdsa_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...>
      ...> public_key = BSV.Crypto.ECDSA.generate_key_pair(private_key: ecdsa_key.private_key)
      ...> |> elem(0)
      ...> public_key == ecdsa_key.public_key
      true
  """
  @spec generate_key_pair(keyword) :: {binary, binary}
  def generate_key_pair(options \\ []) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    private_key = Keyword.get(options, :private_key)
    cond do
      is_binary(private_key) -> :crypto.generate_key(:ecdh, named_curve, private_key)
      true -> :crypto.generate_key(:ecdh, named_curve)
    end
  end


  @doc """
  Creates a signature for the given message, using the given private key.

  ## Options

  The accepted options are:

  * `:named_curve` - Specific the elliptic curve name. Defaults to `:secp256k1`.
  * `:encoding` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Crypto.ECDSA.sign("hello world", private_key, encoding: :base64)
      << signature >>
  """
  @spec sign(binary, PrivateKey.t | binary, keyword) :: binary
  def sign(message, private_key, options \\ [])

  def sign(message, %PrivateKey{} = ecdsa_key, options) do
    encoding = Keyword.get(options, :encoding)

    :public_key.sign(message, :sha256, PrivateKey.as_sequence(ecdsa_key))
    |> Util.encode(encoding)
  end

  def sign(message, private_key, options) when is_binary(private_key) do
    encoding = Keyword.get(options, :encoding)
    named_curve = Keyword.get(options, :named_curve, @named_curve)

    :crypto.sign(:ecdsa, :sha256, message, [private_key, named_curve])
    |> Util.encode(encoding)
  end


  @doc """
  Verify the given message and signature, using the given public key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the given signature with either the `:base64` or `:hex` encoding scheme.
  * `:named_curve` - Specific the elliptic curve name. Defaults to `:secp256k1`.

  ## Examples
  
      BSV.Crypto.ECDSA.verify(signature, message, public_key)
      true
  """
  @spec verify(binary, binary, PublicKey.t | binary, keyword) :: boolean
  def verify(signature, message, public_key, options \\ [])

  def verify(signature, message, %PublicKey{} = public_key, options) do
    encoding = Keyword.get(options, :encoding)
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    signature = Util.decode(signature, encoding)
    :public_key.verify(message, :sha256, signature, {PublicKey.as_sequence(public_key), {:namedCurve, named_curve}})
  end

  def verify(signature, message, public_key, options) when is_binary(public_key) do
    encoding = Keyword.get(options, :encoding)
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    signature = Util.decode(signature, encoding)
    :crypto.verify(:ecdsa, :sha256, message, signature, [public_key, named_curve])
  end


  @doc """
  Decodes the given PEM string into a ECDSA key.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> pem = BSV.Crypto.ECDSA.pem_encode(ecdsa_key)
      ...>
      ...> imported_key = BSV.Crypto.ECDSA.pem_decode(pem)
      ...> imported_key == ecdsa_key
      true
  """
  @spec pem_decode(binary) :: PrivateKey.t
  def pem_decode(pem) do
    :public_key.pem_decode(pem)
    |> List.first
    |> :public_key.pem_entry_decode
    |> PrivateKey.from_sequence
  end


  @doc """
  Encodes the given public or private key into a PEM string.

  ## Examples

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.pem_encode
      ...> |> String.starts_with?("-----BEGIN EC PRIVATE KEY-----")
      true
  """
  @spec pem_encode(PrivateKey.t) :: binary
  def pem_encode(%PrivateKey{} = ecdsa_key) do
    pem_entry = :public_key.pem_entry_encode(:ECPrivateKey, PrivateKey.as_sequence(ecdsa_key))
    :public_key.pem_encode([pem_entry])
  end
  
end
