defmodule GitTest do
  use ExUnit.Case

  test "Github local repo url" do
    {status, url} = Git.parse_origin_url()
    assert status === :ok
    assert String.starts_with?(url, "https://github.com/jan25/changeloggen")
  end
    
end