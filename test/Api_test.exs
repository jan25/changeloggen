defmodule ApiTest do
  use ExUnit.Case

  test "mock prs test" do
    assert is_list(Api.mock_prs())
  end
end
  