defmodule Dhcp.Helpers do
  @moduledoc false

  alias Dhcp.Entry

  @spec create_atom_name(String.t(), String.t()) :: atom()
  def create_atom_name(ip_address, subnet) do
    name = [ip_address, subnet] |> Enum.join("/")

    try do
      String.to_existing_atom(name)
    rescue
      ArgumentError ->
        String.to_atom(name)
    end
  end

  @spec get_date_time_now() :: Integer.t()
  def get_date_time_now() do
    :calendar.local_time()
    |> :calendar.datetime_to_gregorian_seconds()
  end

  @spec get_entry_pid(Entry.t()) :: pid() | nil
  def get_entry_pid(%Entry{} = entry),
    do: Process.whereis(create_atom_name(entry.ip_address, entry.subnet))
end
