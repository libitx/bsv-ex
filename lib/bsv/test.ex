defmodule BSV.Test do
  @moduledoc """
  A variety of helper functions to make the tests consistent
  in their usage of keys, etc.
  """

  @doc """
  Returns a generic symetric key.
  """
  def symetric_key do
    <<225, 142, 18, 176, 144, 89, 142, 193, 18, 237, 201, 84, 109, 62, 36, 67, 233,
      244, 170, 233, 98, 100, 18, 201, 118, 69, 91, 182, 242, 255, 173, 106>>
  end

  @doc """
  Returns an initialization vector of 12 bytes.
  """
  def iv12 do
    <<50, 75, 191, 85, 4, 124, 185, 253, 212, 34, 64, 169>>
  end

  @doc """
  Returns an initialization vector of 16 bytes.
  """
  def iv16 do
    <<245, 64, 39, 93, 45, 251, 164, 144, 160, 20, 159, 238, 26, 236, 140, 161>>
  end
  
end