defmodule PR do
  @enforce_keys [:title, :number, :user, :merged_at]
  defstruct [:title, :labels, :number, :user, :merged_at]
end

defimpl String.Chars, for: PR do
  def to_string(pr), do: "#{pr.title} (##{pr.number}, @#{pr.user})"
end

defmodule Api do

  @doc """
  Template for Github endpoint useful to fetch Pull requests list
  """
  defp list_pr_endpoint do
    "https://api.github.com/repos/{owner}/{repo}/pulls?state=open"
  end

  @doc """
  Parses raw github repository url and returns owner, repository name
  """
  defp parse_url(repo_url) when is_bitstring(repo_url) do
    case Regex.named_captures(~r/github.com\/(?<owner>[^\/]+)\/(?<repo>[^\/]+).*/, repo_url) do
      nil ->
        {:error, "Invalid repo_url: #{repo_url}"}

      %{"owner" => owner, "repo" => repo} ->
        {:ok, {owner, repo}}
    end
  end

  @doc """
  Calls Github Pull requests list endpoint
  """
  defp github_pr_list(owner, repo) when is_bitstring(owner) and is_bitstring(repo) do
    url =
      String.replace(list_pr_endpoint(), "{owner}", owner)
      |> String.replace("{repo}", repo)

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Poison.decode(body) do
          {:ok, body} -> {:ok, body}
          error -> error
        end

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, "Repository not found"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches PR list, parses and returns list of PR structs
  """
  def fetch_pr_list(repo_url) when is_bitstring(repo_url) do
    case parse_url(repo_url) do
      {:ok, {owner, repo}} ->
        github_pr_list(owner, repo)
        |> decode_pr_list()
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Decodes Github response struct to PR struct
  """
  def decode_pr_list({:error, reason}), do: {:error, reason}
  def decode_pr_list({:ok, response}) when is_list(response) do
    # Filter for merged PRs and decode
    Enum.filter(response, fn pr -> pr["merged_at"] !== nil end)
    |> Enum.map(fn pr ->
      %PR{
        # sad that pr.title won't work. These are different %{title: "title"} and %{"title" => "title"}
        title: pr["title"],
        number: pr["number"],
        user: pr["user"]["login"],
        merged_at: pr["merged_at"],
        labels: Enum.map(pr["labels"], fn label -> label["name"] end)
      }
    end)
  end

  defp filter_prs(pr_list, release) when is_list(pr_list) and is_bitstring(release) do
    Enum.filter(pr_list, fn pr -> pr.merged_at !== nil end)
  end

  defp get_prs({owner, repo, release})
       when is_bitstring(owner) and is_bitstring(repo) and is_bitstring(release) do
    case github_pr_list({owner, repo}) do
      {:ok, pr_map_list} when is_list(pr_map_list) ->
        {:ok, filter_prs(pr_map_list, release)}

      {:error, reason} ->
        {:error, reason}

      _ ->
        {:error, "Unknown error"}
    end
  end

  def get_prs(repo_url, release) when is_bitstring(repo_url) and is_bitstring(release) do
    case parse_url(repo_url) do
      {:ok, {owner, repo}} -> get_prs({owner, repo, release})
      error -> error
    end
  end

  def get_prs_since(repo_url, since_time) when is_bitstring(repo_url) and is_bitstring(since_time) do
    # case parse_url(repo_url) do
    #   :ok, {owner, repo} ->

    # end
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

  defp make_groups([], groups), do: groups

  defp make_groups(prs, groups) when is_list(prs) and is_map(groups) do
    [pr | tail] = prs
    make_groups(tail, append_pr(pr, groups))
  end

  @doc """
  Groups a list of PRs by supplied labels
  """
  def group_by_labels(prs, labels \\ []) when is_list(prs) and is_list(labels) do
    {_, empty_groups} =
      Enum.map_reduce(labels, %{}, fn label, groups ->
        {label, Map.put(groups, label, [])}
      end)

    make_groups(prs, empty_groups)
  end

  def mock_prs() do
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
        labels: ["feature", "0.1.0"]
      }
    ]
  end

end
