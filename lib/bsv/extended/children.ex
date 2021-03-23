defmodule BSV.Extended.Children do
  @moduledoc """
  Module for deriving children from BIP-32 extended keys.
  """
  alias BSV.Crypto.{Hash, Secp256k1}
  alias BSV.Crypto.ECDSA
  alias BSV.Extended.{PublicKey, PrivateKey}

  @curve_order 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  @mersenne_prime 2_147_483_647

  defguardp hardened?(index) when index > @mersenne_prime
  defguardp normal?(index) when index > -1 and index <= @mersenne_prime


  @doc """
  Derives a child key from the given extended private or public key, using the
  specified path.

  ## Examples

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.Children.derive("m/44'/0'/0'/0/0")
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "1DB7ijqNz91PPTZyv5StZ8DjjMr69chuwH"

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.Children.derive("m/44'/0'/0'/0/9")
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "12g4iEyKXndS6qwhLkqxzchep4GwVFUUNJ"

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.Children.derive("m/44'/0'/1'/0/5")
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "15JvhMtjeRLewqn2hNSdty4zmEvTJYCPcq"
  """
  @spec derive(PublicKey.t | PrivateKey.t, String.t) :: PublicKey.t | PrivateKey.t
  def derive(key, path) do
    with {kind, pathlist} <- get_pathlist(path),
         do: derive_pathlist(key, pathlist, kind)
  end


  # Private. Returns a list of integers from the given path string
  defp get_pathlist(<<"m/", path::binary>>), do: {:private, get_pathlist(path)}
  defp get_pathlist(<<"M/", path::binary>>), do: {:public, get_pathlist(path)}

  defp get_pathlist(path) do
    String.split(path, "/")
    |> Enum.map(&path_chunk_to_integer/1)
  end

  # Private. Returns a hardened or normal integer from the given path chunk
  defp path_chunk_to_integer(chunk) do
    case String.reverse(chunk) do
      <<"'", rev_chunk::binary>> ->
        String.reverse(rev_chunk)
        |> String.to_integer
        |> Kernel.+(1)
        |> Kernel.+(@mersenne_prime)
      _ ->
        String.to_integer(chunk)
    end
  end


  # Private. Iterrates over the pathlist to derive keys
  defp derive_pathlist(%PublicKey{} = key, [], :public), do: key
  defp derive_pathlist(%PrivateKey{} = key, [], :private), do: key

  defp derive_pathlist(%PrivateKey{} = key, [], :public),
    do: PrivateKey.get_public_key(key)

  defp derive_pathlist(%PublicKey{}, [], :private),
    do: raise "Cannot derive Private Child from a Public Parent!"

  defp derive_pathlist(key, [index | rest], kind) do
    with {child_key, child_chain} <- derive_key(key, index) do
      struct(key.__struct__, [
        network: key.network,
        version_number: key.version_number,
        key: child_key,
        chain_code: child_chain,
        depth: key.depth + 1,
        fingerprint: get_fingerprint(key),
        child_number: index
      ])
      |> derive_pathlist(rest, kind)
    end
  end


  # Private. Derives an extended private or public key from the given index
  defp derive_key(%PrivateKey{} = private_key, index) when normal?(index) do
    {pub_key, _priv_key} = ECDSA.generate_key_pair(private_key: private_key.key)
    public_key = ECDSA.PublicKey.compress(pub_key)

    <<public_key::binary, index::32>>
    |> Hash.hmac(:sha512, private_key.chain_code)
    |> derive_private_key(private_key)
  end

  defp derive_key(%PrivateKey{} = private_key, index) when hardened?(index) do
    <<0::8, private_key.key::binary, index::32>>
    |> Hash.hmac(:sha512, private_key.chain_code)
    |> derive_private_key(private_key)
  end

  defp derive_key(%PublicKey{} = public_key, index) when normal?(index) do
    pub_key = ECDSA.PublicKey.compress(public_key.key)

    <<pub_key::binary, index::32>>
    |> Hash.hmac(:sha512, public_key.chain_code)
    |> derive_public_key(public_key)
  end

  defp derive_key(%PublicKey{}, index) when hardened?(index),
    do: raise "Cannot derive Public Hardened Child!"


  # Private. Derives a private key
  defp derive_private_key(
    <<derived_key::256, child_chain::binary>>,
    %PrivateKey{key: <<key::256>>})
  do
    child_key = derived_key
    |> Kernel.+(key)
    |> rem(@curve_order)
    |> :binary.encode_unsigned()
    |> pad_bytes

    {child_key, child_chain}
  end


  # Private. Derives a public key
  defp derive_public_key(
    <<derived_key::binary-32, child_chain::binary>>,
    %PublicKey{key: key})
  do
    public_child_key = Secp256k1.pubkey_add(key, derived_key)
    {public_child_key, child_chain}
  end


  # Private. Pads bytes with leading zeros if necessary
  defp pad_bytes(bytes) when byte_size(bytes) >= 32, do: bytes
  defp pad_bytes(bytes) do
    padding = 32 - byte_size(bytes)
    :binary.copy(<<0>>, padding) <> bytes
  end


  # Private. Gets a fingerpinrt from the given private or public key
  defp get_fingerprint(%PrivateKey{} = key),
    do: PrivateKey.get_public_key(key) |> get_fingerprint

  defp get_fingerprint(%PublicKey{key: key}), do: get_fingerprint(key)

  defp get_fingerprint(key) when is_binary(key) do
    <<fingerprint::binary-4, _::binary>> = ECDSA.PublicKey.compress(key)
    |> Hash.sha256_ripemd160
    fingerprint
  end

end
