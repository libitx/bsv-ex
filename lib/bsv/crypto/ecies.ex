defmodule BSV.Crypto.ECIES do
  @moduledoc """
  Functions for use with ECIES asymmetric encryption. Is compatible with
  ElectrumSV and bsv.js. Internally uses `libsecp256k1` NIF bindings.

  ## Examples

      iex> {public_key, private_key} = BSV.Crypto.ECDSA.generate_key_pair
      ...>
      ...> "hello world"
      ...> |> BSV.Crypto.ECIES.encrypt(public_key)
      ...> |> BSV.Crypto.ECIES.decrypt(private_key)
      "hello world"
  """
  alias BSV.Util
  alias BSV.Crypto.Hash
  alias BSV.Crypto.AES
  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.ECDSA.{PublicKey, PrivateKey}


  @doc """
  Encrypts the given data with the given public key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Crypto.ECIES.encrypt("hello world", public_key)
      << encrypted binary >>
  """
  @spec encrypt(binary, PublicKey.t | binary, keyword) :: binary
  def encrypt(data, public_key, options \\ [])

  def encrypt(data, %PublicKey{point: public_key}, options) do
    encrypt(data, public_key, options)
  end

  def encrypt(data, public_key, options) when is_binary(public_key) do
    encoding = Keyword.get(options, :encoding)

    # Generate ephemeral keypair
    {ephemeral_pubkey, ephemeral_privkey} = ECDSA.generate_key_pair

    # Derive ECDH key and sha512 hash
    key_hash = with {:ok, ecdh_key} <-
        :libsecp256k1.ec_pubkey_tweak_mul(public_key, ephemeral_privkey)
    do
      ecdh_key |> PublicKey.compress |> Hash.sha512
    end

    # iv and keyE used in AES, keyM used in HMAC
    <<iv::binary-16, keyE::binary-16, keyM::binary-32>> = key_hash
    cyphertext = AES.encrypt(data, :cbc, keyE, iv: iv)
    encrypted = "BIE1" <> PublicKey.compress(ephemeral_pubkey) <> cyphertext
    mac = Hash.hmac(encrypted, :sha256, keyM)

    <<encrypted::binary, mac::binary>>
    |> Util.encode(encoding)
  end


  @doc """
  Decrypts the encrypted data with the given private key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the given cipher text with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Crypto.ECIES.decrypt(encrypted_binary, private_key)
      << decrypted binary >>
  """
  @spec decrypt(binary, PrivateKey.t | binary, keyword) :: binary
  def decrypt(data, private_key, options \\ [])

  def decrypt(data, %PrivateKey{} = private_key, options) do
    decrypt(data, private_key.private_key, options)
  end

  def decrypt(data, private_key, options) when is_binary(private_key) do
    encoding = Keyword.get(options, :encoding)

    encrypted = Util.decode(data, encoding)
    len = byte_size(encrypted) - 69

    <<
      "BIE1",                         # magic bytes
      ephemeral_pubkey::binary-33,    # ephermeral pubkey
      ciphertext::binary-size(len),   # ciphertext
      mac::binary-32                  # mac hash
    >> = encrypted

    # Derive ECDH key and sha512 hash
    key_hash = with {:ok, pub_key} <-
        :libsecp256k1.ec_pubkey_decompress(ephemeral_pubkey),
      {:ok, ecdh_key} <-
        :libsecp256k1.ec_pubkey_tweak_mul(pub_key, private_key)
    do
      ecdh_key |> PublicKey.compress |> Hash.sha512
    else
      err -> raise err
    end

    # iv and keyE used in AES, keyM used in HMAC
    <<iv::binary-16, keyE::binary-16, keyM::binary-32>> = key_hash

    cond do
      Hash.hmac(encrypted, :sha256, keyM) == mac ->
        raise "mac validation failed"
      true -> AES.decrypt(ciphertext, :cbc, keyE, iv: iv)
    end
  end

end
