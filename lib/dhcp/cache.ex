defmodule Dhcp.Cache do
  @moduledoc """
  Cache with with TTL. Implemented as GenServer. Each process will at as on cache entry
  """
  use GenServer
  require Logger

  alias Dhcp.Entry
  import Dhcp.Helpers

  def start_link(
        %Entry{ttl_in_sec: _, start_time: _, ip_address: ip_address, subnet: subnet} = init_args,
        opts \\ []
      ) do
    default_opts = [name: create_atom_name(ip_address, subnet)]
    opts = Keyword.merge(default_opts, opts)

    GenServer.start_link(__MODULE__, init_args, opts)
  end

  @impl true
  def init(%Entry{
        ttl_in_sec: ttl_in_sec,
        start_time: start_time,
        ip_address: ip_address,
        subnet: subnet
      }) do
    case time_left(start_time, ttl_in_sec) do
      0 ->
        Logger.debug("#{ip_address}/#{subnet} TTL has already expired")
        :ignore

      new_ttl_in_sec ->
        state =
          Entry.new(
            ttl_in_sec: new_ttl_in_sec,
            start_time: start_time,
            ip_address: ip_address,
            subnet: subnet
          )

        timeout = new_ttl_in_sec * 1000
        {:ok, state, timeout}
    end
  end

  @impl true
  def handle_cast({:renew_ttl_in_sec, new_ttl_in_sec, start_time}, state) do
    new_state =
      state
      |> Map.update!(:ttl_in_sec, fn _ -> new_ttl_in_sec end)
      |> Map.update!(:start_time, fn _ -> start_time end)

    timeout = new_ttl_in_sec * 1000
    {:noreply, new_state, timeout}
  end

  @impl true
  def handle_info(:timeout, state) do
    Logger.debug("#{create_atom_name(state.ip_address, state.subnet)} TTL is expired !!!")
    {:stop, {:shutdown, state}, state}
  end

  # client side APIs

  def new(%Entry{} = entry), do: start_link(entry)

  def renew_ttl(pid, new_ttl_in_sec, start_time) do
    # todo: check if pid exists
    GenServer.cast(pid, {:renew_ttl_in_sec, new_ttl_in_sec, start_time})
  end

  def delete(pid), do: GenServer.stop(pid)

  # others

  defp time_left(start_time, ttl_in_sec) do
    current_time = get_date_time_now()
    time_elapsed = current_time - start_time

    case ttl_in_sec - time_elapsed do
      time when time <= 0 -> 0
      time -> time
    end
  end
end
