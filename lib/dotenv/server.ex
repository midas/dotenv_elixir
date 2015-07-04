defmodule Dotenv.Server do
  @moduledoc false
  use GenServer

  @reload_timeout_in_minutes 5

  def start_link(env_path) do
    :gen_server.start_link({:local, :dotenv}, __MODULE__, env_path, [])
  end

  def init(env_path) do
    ensure_file_exists(env_path)
    env = Dotenv.load!(env_path)
    Process.send_after self, :auto_reload, reload_timeout_in_ms
    {:ok, env}
  end

  def handle_cast(:reload!, env) do
    {:noreply, Dotenv.load!(env.paths)}
  end

  def handle_cast({:reload!, env_path}, _env) do
    {:noreply, Dotenv.load!(env_path)}
  end

  def handle_call(:env, _from, env) do
    {:reply, env, env}
  end

  def handle_call({:get, key, fallback}, _from, env) do
    {:reply, Dotenv.Env.get(env, fallback, key), env}
  end

  def handle_info(:auto_reload, env) do
    env = Dotenv.load!(env.paths)
    Process.send_after self, :auto_reload, reload_timeout_in_ms
    {:noreply, env}
  end

  defp reload_timeout_in_ms do
    @reload_timeout_in_minutes * 60 * 1000
  end

  defp ensure_file_exists(filename) do
    filename = case filename do
      :automatic -> ".env"
      _          -> filename
    end

    case File.exists?(filename) do
      false ->
        IO.puts "Env file #{filename} does not exist."
        :timer.sleep(1000)
        System.halt(1)
      true  -> true
    end
  end

end
