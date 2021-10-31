defmodule BSV.DecodeError do
  @moduledoc false
  defexception [:reason]

  @impl true
  def exception(reason),
    do: %__MODULE__{reason: reason}

  @impl true
  def message(%__MODULE__{reason: :invalid_address}),
    do: "Invalid Address"

  def message(%__MODULE__{reason: {:invalid_base58_check, version_byte, network}}),
    do: "Invalid version byte `#{ to_string(version_byte) }` for network: #{ to_string(network) }"

  def message(%__MODULE__{reason: {:invalid_encoding, encoding}}),
    do: "Error decoding `#{ to_string(encoding) }` data"

  def message(%__MODULE__{reason: :invalid_header}),
    do: "Invalid block header"

  def message(%__MODULE__{reason: :invalid_merkle_proof}),
    do: "Invalid Merkle proof"

  def message(%__MODULE__{reason: {:invalid_opcode, op}}),
    do: "Invalid Op Code: #{ to_string(op) }"

  def message(%__MODULE__{reason: {:invalid_privkey, length}}),
    do: "Invalid PrivKey length: #{ to_string(length) }"

  def message(%__MODULE__{reason: {:invalid_pubkey, length}}),
    do: "Invalid PubKey length: #{ to_string(length) }"

  def message(%__MODULE__{reason: {:invalid_seed, length}}),
    do: "Invalid seed length: #{ to_string(length) }. Must be between 16 and 64 bytes."

  def message(%__MODULE__{reason: :invalid_varint}),
    do: "Invalid VarInt data"

  def message(%__MODULE__{reason: :invalid_wif}),
    do: "Invalid WIF string"

  def message(%__MODULE__{reason: :invalid_xprv}),
    do: "Invalid xprv string"

  def message(%__MODULE__{reason: :invalid_xpub}),
    do: "Invalid xpub string"

  def message(%__MODULE__{reason: {:param_not_found, params}}),
    do: "Param not found: #{ inspect params }"

end
