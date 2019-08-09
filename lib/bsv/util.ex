defmodule BSV.Util do

  def encode(data, encoding) do
    case encoding do
      :base64 -> Base.encode64(data)
      :hex    -> Base.encode16(data, case: :lower)
      _       -> data
    end
  end

  def random_bytes(bytes) when is_integer(bytes) do
    :crypto.strong_rand_bytes(bytes)
  end
  
end