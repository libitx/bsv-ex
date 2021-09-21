defmodule BSV.Util do
  @moduledoc """
  TODO
  """

  @typedoc "TODO"
  @type encoding() :: :base64, :hex

  @doc """
  TODO
  """
  @spec decode(binary(), encoding()) :: {:ok, binary()} | {:error, term()}
  def decode(data, encoding) do
    case do_decode(data, encoding) do
      {:ok, data} ->
        {:ok, data}
      :error ->
        {:error, {:invalid_encoding, encoding}}
    end
  end

  # TODO
  defp do_decode(data, :base64), do: Base.decode64(data)
  defp do_decode(data, :hex), do: Base.decode16(data, case: :lower)
  defp do_decode(data, _), do: {:ok, data}

  @doc """
  TODO
  """
  @spec decode!(binary(), encoding()) :: binary()
  def decode!(data, encoding) do
    case decode(data, encoding) do
      {:ok, data} ->
        data
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec encode(binary(), encoding()) :: binary()
  def encode(data, :base64), do: Base.encode64(data)
  def encode(data, :hex), do: Base.encode16(data, case: :lower)
  def encode(data, _), do: data

  @doc """
  TODO
  """
  @spec rand_bytes(integer()) :: binary()
  def rand_bytes(bytes) when is_integer(bytes),
    do: :crypto.strong_rand_bytes(bytes)

  @doc """
  TODO
  """
  @spec reverse_bin(binary()) :: binary()
  def reverse_bin(data) when is_binary(data) do
    data
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

end
