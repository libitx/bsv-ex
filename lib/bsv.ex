defmodule BSV do
  @moduledoc """
  TODO
  """

  @typedoc "TODO"
  @type network() :: :main | :test

  @version Mix.Project.config[:version]

  @doc """
  TODO
  """
  @spec network() :: network()
  def network(), do: Application.get_env(:bsv, :network, :main)

  @doc """
  TODO
  """
  @spec version() :: String.t
  def version(), do: @version

end
