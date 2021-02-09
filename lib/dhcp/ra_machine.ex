defmodule Dhcp.RaMachine do
  @moduledoc """
  Implements RA state machine for data replication.
  """
  @behaviour :ra_machine

  alias Dhcp.Cache
  alias Dhcp.Entry
  import Dhcp.Helpers
  require Logger

  @type state :: [Entry.t()]
  @type ra_kv_command :: {:add | :renew | :delete, Entry.t()}

  @impl true
  def init(_machine_init_args), do: []

  @impl true
  def apply(_meta, {:add, %Entry{} = entry}, state) do
    case Cache.new(entry) do
      {:ok, pid} ->
        state = [entry | state]
        effect = {:monitor, :process, pid}
        {state, :ok, effect}

      {:error, {:already_started, pid} = reply} ->
        # fixme: should this be monitored?
        effect = {:monitor, :process, pid}

        state =
          unless Enum.any?(state, fn state_entry -> state_entry.ip_address == entry.ip_address end),
                 do: [entry | state],
                 else: state

        {state, reply, effect}

      :ignore ->
        {state, :ok}
    end
  end

  @impl true
  def apply(_meta, {:delete, %Entry{} = entry}, state) do
    case get_entry_pid(entry) do
      nil ->
        {state, :entry_not_found}

      pid ->
        Cache.delete(pid)

        new_state =
          Enum.reject(state, fn state_entry ->
            state_entry.ip_address == entry.ip_address
          end)

        effect = {:demonitor, :process, pid}
        {new_state, :ok, effect}
    end
  end

  @impl true
  def apply(_meta, {:renew, %Entry{ttl_in_sec: ttl_in_sec, start_time: start_time} = entry}, state) do
    case get_entry_pid(entry) do
      nil ->
        {state, :entry_not_found}

      pid ->
        Cache.renew_ttl(pid, ttl_in_sec, start_time)

        new_state =
          state
          |> Enum.reject(fn state_entry -> state_entry.ip_address == entry.ip_address end)
          |> Kernel.++([entry])

        {new_state, :ok}
    end
  end

  @impl true
  def apply(_meta, {:down, _pid, {:shutdown, %Entry{} = entry}}, state) do
    Logger.error("removing #{inspect(entry)} from ra_machine")

    new_state =
      Enum.reject(state, fn state_entry ->
        state_entry.ip_address == entry.ip_address
      end)

    {new_state, :ok}
  end

  @impl true
  def state_enter(:leader, state) do
    Enum.map(state, fn entry -> {:monitor, :process, get_entry_pid(entry)} end)
  end

  @impl true
  def state_enter(_, _) do
    []
  end

  # client APIs
  def add_entry(
        {_name, _node} = server_id,
        [ttl_in_sec: _, ip_address: _, subnet: _] = entry
      ) do
    # add checks here for input data
    entry = Keyword.put(entry, :start_time, get_date_time_now())
    :ra.process_command(server_id, {:add, Entry.new(entry)})
  end

  def delete_entry(
        {_name, _node} = server_id,
        ip_address: ip_address,
        subnet: subnet
      ) do
    :ra.process_command(server_id, {:delete, %Entry{ip_address: ip_address, subnet: subnet}})
  end

  def renew_entry_ttl(
        {_name, _node} = server_id,
        [ttl_in_sec: _, ip_address: _, subnet: _] = entry
      ) do
    entry = Keyword.put(entry, :start_time, get_date_time_now())
    :ra.process_command(server_id, {:renew, Entry.new(entry)})
  end

  def test_start() do
    cluster_name = :dhcp

    server_ids = [
      {cluster_name, :dhcp_1@USMC02C80VDMD6R},
      {cluster_name, :dhcp_2@USMC02C80VDMD6R},
      {cluster_name, :dhcp_3@USMC02C80VDMD6R}
    ]

    machine = {:module, Dhcp.RaMachine, %{}}
    :ra.start_or_restart_cluster(cluster_name, machine, server_ids)
  end
end
