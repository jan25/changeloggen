defmodule PR do
  @enforce_keys [:title, :number, :user]
  defstruct [:title, :labels, :number, :user]
end

defimpl String.Chars, for: PR do
  def to_string(pr), do: "#{pr.title} (##{pr.number}, @#{pr.user})"
end

defmodule Api do

  defp list_pr_query do
    "repo:{owner}/{repo} is:pr merged:>={utc_timestamp}"
  end

  @doc """
  Parses raw github repository url and returns owner, repository name

  Sample input:
  github.com/jan25/changeloggen/some-folder
  github.com/jan25/changeloggen.git
  """
  def parse_url(repo_url) when is_bitstring(repo_url) do
    case Regex.named_captures(~r/github.com\/(?<owner>[^\/]+)\/(?<repo>[^\/\.]+).*/, repo_url) do
      nil ->
        {:error, "Invalid repo_url: #{repo_url}"}

      %{"owner" => owner, "repo" => repo} ->
        {:ok, {owner, repo}}
    end
  end

  @doc """
  Fetches latest release published_at timestamp
  """
  def get_last_release_timestamp(repo_url) do
    case parse_url(repo_url) do
      {:ok, {owner, repo}} -> get_last_release_timestamp(owner, repo)
      {:error, reason} -> {:error, reason}
    end
  end

  defp get_last_release_timestamp(owner, repo) do
    case Tentacat.Releases.latest(owner, repo) do
      {200, release, _} ->
        {:ok, release["published_at"]}
      _ ->
        # because api returns 404 when no release is available
        {:ok, "1970-01-01T00:00:00Z"}
        # {:error, reason}
    end
  end

  @doc """
  Fetches PR list, parses and returns list of PR structs
  """
  def fetch_pr_list(repo_url, from_time) when is_bitstring(repo_url) and is_bitstring(from_time) do
    case parse_url(repo_url) do
      {:ok, {owner, repo}} ->
        fetch_pr_list(owner, repo, from_time)
        |> decode_pr_search_response()
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_pr_list(owner, repo, from_time) do
    q = String.replace(list_pr_query(), "{owner}", owner)
    |> String.replace("{repo}", repo)
    |> String.replace("{utc_timestamp}", from_time)
    Tentacat.Search.issues(%{ q: q })
  end
      
  defp decode_pr_search_response({200, %{"items" => pr_list}, _}) when is_list(pr_list) do
    # Filter for merged PRs and decode
    decoded = Enum.map(pr_list, fn pr ->
      %PR{
        # sad that pr.title won't work. These are different %{title: "title"} and %{"title" => "title"}
        title: pr["title"],
        number: pr["number"],
        user: pr["user"]["login"],
        labels: Enum.map(pr["labels"], fn label -> label["name"] end)
      }
    end)
    {:ok, decoded}
  end
  
  defp decode_pr_search_response({_, _, _}), do: {:error, "Failed to fetch pull requests"}

  @doc """
  Get list of PRs since latest release.

  Returns all PRs to the repo if no release is available.
  """
  def get_prs_after_last_release(repo_url) when is_bitstring(repo_url) do
    case get_last_release_timestamp(repo_url) do
      {:ok, release_timestamp} ->
        fetch_pr_list(repo_url, release_timestamp)
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Groups a list of PRs by supplied labels
  """
  def group_by_labels(prs, labels) when is_list(prs) and is_list(labels) do
    {_, empty_groups} =
      Enum.map_reduce(labels, %{}, fn label, groups ->
        {label, Map.put(groups, label, [])}
      end)

    make_groups(prs, empty_groups)
  end

  defp make_groups([], groups), do: groups

  defp make_groups(prs, groups) when is_list(prs) and is_map(groups) do
    [pr | tail] = prs
    make_groups(tail, append_pr(pr, groups))
  end

  defp append_pr(_, [], groups), do: groups

  defp append_pr(pr, labels, groups) when is_list(labels) and is_map(groups) do
    [label | tail] = labels

    cond do
      Map.has_key?(groups, label) ->
        groups = Map.put(groups, label, [pr | groups[label]])
        append_pr(pr, tail, groups)

      true ->
        append_pr(pr, tail, groups)
    end
  end

  defp append_pr(pr, groups), do: append_pr(pr, pr.labels, groups)

end
