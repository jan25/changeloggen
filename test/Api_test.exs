defmodule ApiTest do
  use ExUnit.Case

  test "parse git repo url" do
    {status, _} = Api.parse_url("fakerepourl")
    assert status === :error

    {status, result} = Api.parse_url("github.com/jan25/termracer")
    assert status === :ok
    assert result === {"jan25", "termracer"}

    {status, result} = Api.parse_url("github.com/jan25/termracer/somefolder")
    assert status === :ok
    assert result === {"jan25", "termracer"}
  end

  test "latest release timestamp" do
    {status, _} = Api.get_last_release_timestamp("fakerepourl")
    assert status === :error

    # Test that last release happened some time after the epoch
    {status, result} = Api.get_last_release_timestamp("github.com/jan25/termracer")
    assert status === :ok
    assert DateTime.compare(elem(DateTime.from_unix(0), 1), elem(DateTime.from_iso8601(result), 1)) === :lt
  end

  test "fetch pull requests" do
    {status, _} = Api.get_prs_after_last_release("fakerepourl")
    assert status === :error

    {status, pr_list} = Api.get_prs_after_last_release("github.com/jan25/changeloggen")
    assert status === :ok
    assert is_list(pr_list)
  end

  test "group by labels" do
    groups = Api.group_by_labels(mock_pr_list(), ["0.1.0", "bug"])
    assert Map.has_key?(groups, "0.1.0")
    assert Map.has_key?(groups, "bug")
    assert is_list(groups["0.1.0"]) and length(groups["0.1.0"]) == 2
    assert is_list(groups["bug"]) and length(groups["bug"]) == 2
  end

  defp mock_pr_list() do
    [
      %PR{
        title: "test1",
        number: 1,
        user: "user1",
        labels: ["bug", "0.1.0"]
      },
      %PR{
        title: "test2",
        number: 2,
        user: "user2",
        labels: ["bug", "0.1.0"]
      }
    ]
  end
end
  