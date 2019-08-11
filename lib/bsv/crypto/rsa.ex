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
  
  """
  alias BSV.Util
  alias BSV.Crypto.RSA.PublicKey
  alias BSV.Crypto.RSA.PrivateKey


  @doc """
  Generate a new public and private keypair.
  """
  @spec generate_key_pair(integer) :: {BSV.Crypto.RSA.PublicKey.t, BSV.Crypto.RSA.PrivateKey.t}
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
  @spec encrypt(binary, BSV.Crypto.RSA.PublicKey.t | {:public, BSV.Crypto.RSA.PublicKey.t} | {:private, BSV.Crypto.RSA.PrivateKey.t}, list) :: binary
  def encrypt(data, key, options \\ [])

  def encrypt(data, {:public, public_key}, options) do
    encoding = Keyword.get(options, :encode)
    :public_key.encrypt_public(data, PublicKey.as_sequence(public_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
    |> Util.encode(encoding)
  end

  def encrypt(data, {:private, private_key}, options) do
    encoding = Keyword.get(options, :encode)
    :public_key.encrypt_private(data, PrivateKey.as_sequence(private_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
    |> Util.encode(encoding)
  end

  def encrypt(data, public_key, options), do: encrypt(data, {:public, public_key}, options)

  
  @doc """
  Decrypts the encrypted data with the given public or private key.

  The method implicitly assumes the use of a private key, but decryption is possible with a public key by passing the key in a tuple format: `{:public, public_key}`.

  ## Examples

      {public_key, private_key} = BSV.Crypto.RSA.generate_key_pair
      
      BSV.Crypto.RSA.decrypt(encrypted_binary, private_key)
      << decrypted binary >>
      
      # Encryption with a private key
      BSV.Crypto.RSA.decrypt(encrypted_binary, {:public, public_key})
      << decrypted binary >>
  """
  @spec decrypt(binary, BSV.Crypto.RSA.PublicKey.t | {:public, BSV.Crypto.RSA.PublicKey.t} | {:private, BSV.Crypto.RSA.PrivateKey.t}, list) :: binary
  def decrypt(data, key, options \\ [])

  def decrypt(data, {:public, public_key}, _options) do
    :public_key.decrypt_public(data, PublicKey.as_sequence(public_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
  end

  def decrypt(data, {:private, private_key}, _options) do
    :public_key.decrypt_private(data, PrivateKey.as_sequence(private_key), rsa_padding: :rsa_pkcs1_oaep_padding, rsa_oaep_md: :sha256)
  end

  def decrypt(data, private_key, options), do: decrypt(data, {:private, private_key}, options)
  
end