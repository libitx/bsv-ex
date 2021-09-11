defmodule BSV.Hash do
  @moduledoc """
  TODO
  """

  @doc """
  TODO
  """
  @spec ripemd160(binary(), keyword()) :: binary()
  def ripemd160(data, opts \\ []) when is_binary(data),
    do: hash(data, :ripemd160, opts)


  @doc """
  TODO
  """
  @spec sha1(binary(), keyword()) :: binary()
  def sha1(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha, opts)


  @doc """
  TODO
  """
  @spec sha1_hmac(binary(), binary(), keyword()) :: binary()
  def sha1_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha, opts)


  @doc """
  TODO
  """
  @spec sha256(binary(), keyword()) :: binary()
  def sha256(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha256, opts)


  @doc """
  TODO
  """
  @spec sha256_hmac(binary(), binary(), keyword()) :: binary()
  def sha256_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha256, opts)


  @doc """
  TODO
  """
  @spec sha512(binary(), keyword()) :: binary()
  def sha512(data, opts \\ []) when is_binary(data),
    do: hash(data, :sha512, opts)


  @doc """
  TODO
  """
  @spec sha512_hmac(binary(), binary(), keyword()) :: binary()
  def sha512_hmac(data, key, opts \\ [])
    when is_binary(data) and is_binary(key),
    do: hmac(data, key, :sha512, opts)


  @doc """
  TODO
  """
  @spec sha256_ripemd160(binary(), keyword()) :: binary()
  def sha256_ripemd160(data, opts \\ []) when is_binary(data),
    do: sha256(data) |> ripemd160(opts)


  @doc """
  TODO
  """
  @spec sha256_sha256(binary(), keyword()) :: binary()
  def sha256_sha256(data, opts \\ []) when is_binary(data),
    do: sha256(data) |> sha256(opts)


  # Computes the hash of the given binary using the specified algorithm
  defp hash(data, alg, _opts) do
    :crypto.hash(algorithm, data)
  end


  # Computes the hmac of the given binary with the key, using the specified
  # algorithm
  defp hmac(data, key, alg, _opts) do
    :crypto.mac(:hmac, :sha256, key, data)
  end

end
