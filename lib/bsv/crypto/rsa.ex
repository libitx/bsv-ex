defmodule BSV.Crypto.RSA do
  @moduledoc """
  Functions for use with RSA asymmetric cryptography.

  ## Examples

      iex> {public_key, private_key} = BSV.Crypto.RSA.generate_key_pair
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.RSA.encrypt(public_key)
      ...> |> BSV.Crypto.RSA.decrypt(private_key)
      "hello world"

      iex> {public_key, private_key} = BSV.Crypto.RSA.generate_key_pair
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.RSA.encrypt(private_key)
      ...> |> BSV.Crypto.RSA.decrypt(public_key)
      "hello world"
  
  """
  alias BSV.Util
  alias BSV.Crypto.RSA.PublicKey
  alias BSV.Crypto.RSA.PrivateKey


  @doc """
  Generate a new public and private keypair.
  """
  @spec generate_key_pair(integer) :: {PublicKey.t, PrivateKey.t}
  def generate_key_pair(bits \\ 2048) do
    private_key = :public_key.generate_key({:rsa, bits, <<1,0,1>>})
    |> PrivateKey.from_sequence
    {PrivateKey.get_public_key(private_key), private_key}
  end


  @doc """
  Encrypts the given data with the given public or private key.

  The method implicitly assumes the use of a public key, but encryption is possible with a private key by passing the key in a tuple format: `{:private, private_key}`.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding schema.

  ## Examples

      {public_key, private_key} = BSV.Crypto.RSA.generate_key_pair
      
      BSV.Crypto.RSA.encrypt("hello world", public_key)
      << encrypted binary >>
      
      # Encryption with a private key
      BSV.Crypto.RSA.encrypt("hello world", {:private, private_key})
      << encrypted binary >>
  """
  @spec encrypt(binary, PublicKey.t | {:public, PublicKey.t} | {:private, PrivateKey.t}, list) :: binary
  def encrypt(data, key, options \\ [])

  def encrypt(data, public_key = %PublicKey{}, options) do
    encoding = Keyword.get(options, :encode)
    :public_key.encrypt_public(data, PublicKey.as_sequence(public_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
    |> Util.encode(encoding)
  end

  def encrypt(data, private_key = %PrivateKey{}, options) do
    encoding = Keyword.get(options, :encode)
    :public_key.encrypt_private(data, PrivateKey.as_sequence(private_key))
    |> Util.encode(encoding)
  end

  
  @doc """
  Decrypts the encrypted data with the given public or private key.

  ## Examples

      {public_key, private_key} = BSV.Crypto.RSA.generate_key_pair
      
      BSV.Crypto.RSA.decrypt(encrypted_binary, private_key)
      << decrypted binary >>
  """
  @spec decrypt(binary, PublicKey.t | PrivateKey.t, list) :: binary
  def decrypt(data, key, options \\ [])

  def decrypt(data, public_key = %PublicKey{}, _options) do
    :public_key.decrypt_public(data, PublicKey.as_sequence(public_key))
  end

  def decrypt(data, private_key = %PrivateKey{}, _options) do
    :public_key.decrypt_private(data, PrivateKey.as_sequence(private_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
  end


  @doc """
  TODOC

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...> pem = BSV.Crypto.RSA.pem_encode(public_key)
      ...>
      ...> imported_key = BSV.Crypto.RSA.pem_decode(pem)
      ...> imported_key == public_key
      true
  """
  @spec pem_decode(binary) :: PublicKey.t | PrivateKey.t
  def pem_decode(pem) do
    rsa_key_sequence = :public_key.pem_decode(pem)
    |> List.first
    |> :public_key.pem_entry_decode

    case elem(rsa_key_sequence, 0) do
      :RSAPublicKey -> PublicKey.from_sequence(rsa_key_sequence)
      :RSAPrivateKey -> PrivateKey.from_sequence(rsa_key_sequence)
    end
  end

  @doc """
  TODOC

  ## Examples

      iex> BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...> |> BSV.Crypto.RSA.pem_encode
      ...> |> String.starts_with?("-----BEGIN RSA PUBLIC KEY-----")
      true

      iex> BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_private_key)
      ...> |> BSV.Crypto.RSA.pem_encode
      ...> |> String.starts_with?("-----BEGIN RSA PRIVATE KEY-----")
      true
  """
  @spec pem_encode(PublicKey.t | PrivateKey.t) :: binary
  def pem_encode(public_key = %PublicKey{}) do
    pem_entry = :public_key.pem_entry_encode(:RSAPublicKey, PublicKey.as_sequence(public_key))
    :public_key.pem_encode([pem_entry])
  end

  def pem_encode(private_key = %PrivateKey{}) do
    pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, PrivateKey.as_sequence(private_key))
    :public_key.pem_encode([pem_entry])
  end
  
end