defmodule BSV do
  @moduledoc """
  TODO
  """

  @typedoc "Bitcoin network"
  @type network() :: :main | :test

  @version Mix.Project.config[:version]

  @doc """
  Returns the currently configured Bitcoin network.
  """
  @spec network() :: network()
  def network(), do: Application.get_env(:bsv, :network, :main)

  @doc """
  Returns the version of the BSV-ex hex package.
  """
  @spec version() :: String.t
  def version(), do: @version

end
