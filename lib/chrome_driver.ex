defmodule ChromeDriver do
  @moduledoc """
  A module to manage the ChromeDriver process, including starting, stopping, and checking the status.
  """

  @doc """
  Starts the ChromeDriver process if it's not already running.
  """
  def start do
    case running?() do
      true ->
        Status.info("ChromeDriver is already running.")

      false ->
        Status.ok("Starting ChromeDriver...")
        start_process()
    end
  end

  @doc """
  Stops the ChromeDriver process if it's running.
  """
  def stop do
    case find_chromedriver_pid() do
      {:error, msg} ->
        Status.error(msg)

      {:ok, pid} ->
        Status.ok("Stopping ChromeDriver...")
        kill_pid(pid)
    end
  end

  @doc """
  Checks if the ChromeDriver is running by attempting to connect to its default port.
  """
  def running? do
    :gen_tcp.connect(~c"localhost", 9515, [:binary, packet: :raw, active: false, reuseaddr: true])
    |> case do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _} ->
        false
    end
  end

  ###
  # Starts the ChromeDriver process by finding the executable and launching it with the necessary arguments.
  # Raises an error if the executable is not found.
  ###
  defp start_process do
    port = System.find_executable("chromedriver")

    if port do
      {:ok, _pid} =
        Task.start(fn ->
          System.cmd(port, ["--whitelisted-ips", "", "--allowed-origins", "*"],
            into: IO.stream(:stdio, :line)
          )
        end)

      # Wait a bit for ChromeDriver to start
      Process.sleep(2000)
    else
      raise "ChromeDriver executable not found. Please ensure ChromeDriver is installed and in your PATH."
    end
  end

  ###
  # Finds the PID of the running ChromeDriver process by parsing the output of the `ps` command.
  # Returns `{:ok, pid}` if found, or `{:error, msg}` if not.
  ###
  defp find_chromedriver_pid do
    # Fetch the list of running processes
    {processes, _exit_status} = System.cmd("ps", ["-e", "-o", "pid,command"])

    # Split the output into lines and remove the header
    process_lines =
      processes
      |> String.split("\n")
      |> tl()

    # Find the line containing "chromedriver"
    chromedriver_line =
      Enum.find(process_lines, fn line -> String.contains?(line, "chromedriver") end)

    # Extract the PID from the line
    case chromedriver_line do
      nil ->
        {:error, "chromedriver not found"}

      line ->
        [pid | _] = String.split(String.trim(line))
        {:ok, String.to_integer(pid)}
    end
  end

  ###
  # Kills the process with the given PID using the `kill -9` command.
  # Returns `{:ok, msg}` after killing the process.
  ###
  defp kill_pid(pid) when is_integer(pid) do
    {_, _} = System.cmd("kill", ["-9", Integer.to_string(pid)])
    {:ok, "Killed process with PID #{pid}"}
  end
end
