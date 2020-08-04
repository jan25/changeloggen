defmodule Git do
  def parse_origin_url() do
    case System.cmd("git", String.split("remote get-url origin", " ")) do
      {url, _exit_code = 0} ->
        {:ok, String.trim(url, ".git\n")}

      _ ->
        {:error, "Current directory not a git repository"}
    end
  end
end
