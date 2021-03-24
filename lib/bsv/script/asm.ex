defmodule BSV.Script.ASM do
  @moduledoc """
  Module for parsing and serializing ASM strings to and from Script structs.
  """
  require BSV.Script.OpCode
  alias BSV.{Script, Util}


  @doc """
  Parses the given ASM string into a Script struct.
  """
  @spec parse(String.t) :: Script.t
  def parse(data) do
    chunks = data
    |> String.split(" ")
    |> Enum.map(&parse_chunk/1)

    %Script{chunks: chunks}
  end

  defp parse_chunk(<<"OP_", _::binary>> = chunk),
    do: String.to_existing_atom(chunk)

  defp parse_chunk("-1"), do: :OP_1NEGATE
  defp parse_chunk("0"), do: :OP_0

  defp parse_chunk(chunk), do: Util.decode(chunk, :hex)


  @doc """
  Serializes the given Script into a ASM encoded string.
  """
  @spec parse(Script.t) :: String.t
  def serialize(%Script{chunks: chunks}) do
    chunks
    |> Enum.map(&serialize_chunk/1)
    |> Enum.join(" ")
  end

  defp serialize_chunk(:OP_1NEGATE), do: "-1"
  defp serialize_chunk(chunk) when chunk in [:OP_0, :OP_FALSE], do: "0"
  defp serialize_chunk(chunk) when is_atom(chunk), do: Atom.to_string(chunk)
  defp serialize_chunk(chunk) when is_binary(chunk), do: Util.encode(chunk, :hex)


end
