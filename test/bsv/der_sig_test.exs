defmodule BSV.DERSigTest do
  use ExUnit.Case

  alias BSV.DERSig

  test "simple parse" do
    sig = Base.decode16!("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5", case: :lower)
    struct = %DERSig{
      length: 72,
      r: Base.decode16!("00002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e7366", case: :lower),
      s: Base.decode16!("0000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5", case: :lower),
      r_type: 0x02,
      s_type: 0x02,
      type: 0x30
    }
    assert DERSig.parse(sig) == struct
  end

  test "normalize" do # also tests sorialization
    sig = Base.decode16!("3048022200002b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e736602220000334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5", case: :lower)
    sig_norm = Base.decode16!("304402202b83d59c1d23c08efd82ee0662fec23309c3adbcbd1f0b8695378db4b14e73660220334a96676e58b1bb01784cb7c556dd8ce1c220171904da22e18fe1e7d1510db5", case: :lower)

    assert DERSig.normalize(sig) == sig_norm
    assert DERSig.low_s?(sig_norm) == true
  end

  test "low_s?" do
    sig = Base.decode16!("304502203e4516da7253cf068effec6b95c41221c0cf3a8e6ccb8cbf1725b562e9afde2c022100ab1e3da73d67e32045a20e0b999e049978ea8d6ee5480d485fcf2ce0d03b2ef0", case: :lower)
    assert DERSig.low_s?(sig) == false
  end

  # DERSig.strict?/1 tests included in bitcoin core sript tests

end