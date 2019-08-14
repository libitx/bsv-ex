defmodule BSV.Crypto.RSA do
  @moduledoc """
  Functions for use with RSA asymmetric cryptography.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.generate_key
      ...> public_key = BSV.Crypto.RSA.PrivateKey.get_public_key(private_key)
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.RSA.encrypt(public_key)
      ...> |> BSV.Crypto.RSA.decrypt(private_key)
      "hello world"

      iex> private_key = BSV.Crypto.RSA.generate_key
      ...> public_key = BSV.Crypto.RSA.PrivateKey.get_public_key(private_key)
      ...>
      ...> message = "hello world"
      ...> signature = BSV.Crypto.RSA.sign(message, private_key)
      ...> BSV.Crypto.RSA.verify(message, signature, public_key)
      true
  
  """
  alias BSV.Util
  alias BSV.Crypto.RSA.PublicKey
  alias BSV.Crypto.RSA.PrivateKey


  @doc """
  Generate a new RSA private key.

  ## Options

  The accepted options are:

  * `:size` - Specific the size of the RSA key. Defaults to `2048`.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.generate_key
      ...> (%BSV.Crypto.RSA.PrivateKey{} = private_key) == private_key
      true
  """
  @spec generate_key(list) :: PrivateKey.t
  def generate_key(options \\ []) do
    size = Keyword.get(options, :size, 2048)
    :public_key.generate_key({:rsa, size, <<1,0,1>>})
    |> PrivateKey.from_sequence
  end


  @doc """
  Encrypts the given data with the given public or private key.

  The method implicitly assumes the use of a public key, but encryption is possible with a private key by passing the key in a tuple format: `{:private, private_key}`.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.
  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Crypto.RSA.encrypt("hello world", public_or_private_key)
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

      BSV.Crypto.RSA.decrypt(encrypted_binary, public_or_private_key)
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
  Creates a signature for the given message, using the given private key.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.
  * `:salt_length` - Specify the RSA-PSS salt length (defaults to `20`).

  ## Examples

      BSV.Crypto.RSA.sign("hello world", private_key, encode: :base64)
      << signature >>
  """
  @spec sign(binary, PrivateKey.t, list) :: binary
  def sign(message, private_key = %PrivateKey{}, options \\ []) do
    salt_len = Keyword.get(options, :salt_length, 20)
    encoding = Keyword.get(options, :encode)
    :public_key.sign(message, :sha256, PrivateKey.as_sequence(private_key), rsa_padding: :rsa_pkcs1_pss_padding, rsa_pss_saltlen: salt_len)
    |> Util.encode(encoding)
  end


  @doc """
  Verify the given message and signature, using the given private key.

  ## Options

  The accepted options are:

  * `:salt_length` - Specify the RSA-PSS salt length (defaults to `20`).

  ## Examples
  
      BSV.Crypto.RSA.verify(signature, public_key)
  """
  @spec verify(binary, PublicKey.t, list) :: boolean
  def verify(message, signature, public_key = %PublicKey{}, options \\ []) do
    salt_len = Keyword.get(options, :salt_length, 20)
    :public_key.verify(message, :sha256, signature, PublicKey.as_sequence(public_key), rsa_padding: :rsa_pkcs1_pss_padding, rsa_pss_saltlen: salt_len)
  end


  @doc """
  Decodes the given PEM string into a public or private key.

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
  Encodes the given public or private key into a PEM string.

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
  def pem_encode(key)

  def pem_encode(public_key = %PublicKey{}) do
    pem_entry = :public_key.pem_entry_encode(:RSAPublicKey, PublicKey.as_sequence(public_key))
    :public_key.pem_encode([pem_entry])
  end

  def pem_encode(private_key = %PrivateKey{}) do
    pem_entry = :public_key.pem_entry_encode(:RSAPrivateKey, PrivateKey.as_sequence(private_key))
    :public_key.pem_encode([pem_entry])
  end
  
end