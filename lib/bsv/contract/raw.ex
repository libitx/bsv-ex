defmodule BSV.Contract.Raw do
  @moduledoc """
  TODO
  """
  use BSV.Contract
  alias BSV.Script

  @impl true
  def locking_script(ctx, %{script: %Script{} = script}) do
    Map.put(ctx, :script, script)
  end

  @impl true
  def unlocking_script(ctx, %{script: %Script{} = script}) do
    Map.put(ctx, :script, script)
  end

end
