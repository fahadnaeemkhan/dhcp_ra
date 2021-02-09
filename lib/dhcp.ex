defmodule Dhcp.Entry do
  defstruct [:ttl_in_sec, :start_time, :ip_address, :subnet]

  @type t :: %__MODULE__{
          ttl_in_sec: Integer.t(),
          start_time: Integer.t(),
          ip_address: String.t(),
          subnet: String.t()
        }

  @spec new(Keyword.t()) :: __MODULE__.t()
  def new(entries) do
    ttl_in_sec = Keyword.fetch!(entries, :ttl_in_sec)
    start_time = Keyword.fetch!(entries, :start_time)
    ip_address = Keyword.fetch!(entries, :ip_address)
    subnet = Keyword.fetch!(entries, :subnet)

    %__MODULE__{
      ttl_in_sec: ttl_in_sec,
      start_time: start_time,
      ip_address: ip_address,
      subnet: subnet
    }
  end
end

defmodule Dhcp do
  @moduledoc """
  Documentation for `Dhcp`.
  """
end
