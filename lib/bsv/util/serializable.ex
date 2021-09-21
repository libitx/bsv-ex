defprotocol BSV.Util.Serializable do
  @moduledoc """
  TODO
  """

  @doc """
  TODO
  """
  @spec parse(t(), binary()) :: {:ok, t(), binary()} | {:error, term()}
  def parse(type, data)

  @doc """
  TODO
  """
  @spec serialize(t()) :: binary()
  def serialize(type)

end
