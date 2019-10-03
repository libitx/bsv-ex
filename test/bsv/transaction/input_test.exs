defmodule BSV.Transaction.InputTest do
  use ExUnit.Case
  doctest BSV.Transaction.Input

  setup_all do
    %{
      hex: "7bb22176433bb45bacede86a43764f98c7023f1a79b00138e3d3ea610716a8f1010000006b483045022100c7036739f47361398bd115dbe9302fdc456d75f83fb38e531f4a445c8385138a022006f68ca095a35886f3eb217f416650490a3f0a279f8dc564d0222c884002f85841210232b357c5309644cf4aa72b9b2d8bfe58bdf2515d40119318d5cb51ef378cae7effffffff",
      input: %BSV.Transaction.Input{
        output_txid: "f1a8160761ead3e33801b0791a3f02c7984f76436ae8edac5bb43b437621b27b",
        output_index: 1,
        script: %BSV.Script{
          chunks: [
            <<48, 69, 2, 33, 0, 199, 3, 103, 57, 244, 115, 97, 57, 139, 209, 21, 219,
              233, 48, 47, 220, 69, 109, 117, 248, 63, 179, 142, 83, 31, 74, 68, 92,
              131, 133, 19, 138, 2, 32, 6, 246, 140, 160, 149, 163, 88, 134, 243, 235,
              33, 127, 65, 102, 80, 73, 10, 63, 10, 39, 159, 141, 197, 100, 208, 34,
              44, 136, 64, 2, 248, 88, 65>>,
            <<2, 50, 179, 87, 197, 48, 150, 68, 207, 74, 167, 43, 155, 45, 139, 254,
              88, 189, 242, 81, 93, 64, 17, 147, 24, 213, 203, 81, 239, 55, 140, 174,
              126>>
          ]
        },
        sequence: 4294967295
        
      }
    }
  end


  describe "BSV.Transaction.Input.parse/2" do
    test "must parse single input", ctx do
      {input, ""} = ctx.hex
      |> BSV.Transaction.Input.parse(encoding: :hex)
      assert input.output_txid == "f1a8160761ead3e33801b0791a3f02c7984f76436ae8edac5bb43b437621b27b"
      assert input.sequence == 4294967295
    end
  end


  describe "BSV.Transaction.Input.serialize/2" do
    test "must serialize input to binary", ctx do
      input = BSV.Transaction.Input.serialize(ctx.input, encoding: :hex)
      assert input == ctx.hex
    end
  end

end