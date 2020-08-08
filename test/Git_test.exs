defmodule GitTest do
  use ExUnit.Case

  test "Github local repo url" do
    {status, url} = Git.parse_origin_url()
    assert status === :ok
    assert url === "https://github.com/jan25/changeloggen.git"
  end
    
end