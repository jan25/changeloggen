defmodule PR do
  @enforce_keys [:title, :number, :user]
  defstruct [:title, :labels, :number, :user]
end

defimpl String.Chars, for: PR do
  def to_string(pr), do: "#{pr.title} (##{pr.number}, @#{pr.user})"
end

defmodule Changeloggen do
  @pr_list_url "https://api.github.com/repos/{owner}/{repo}/pulls?state=open"

  defp parse_url(repo_url) when is_bitstring(repo_url) do
    case Regex.named_captures(~r/github.com\/(?<owner>[^\/]+)\/(?<repo>[^\/]+).*/, repo_url) do
      nil ->
        {:error, "Invalid repo_url: #{repo_url}"}
      %{"owner" => owner, "repo" => repo} ->
        {:ok, {owner, repo}}
    end
  end

  defp fetch_pr_list({owner, repo}) when is_bitstring(owner) and is_bitstring(repo) do
    url = String.replace(@pr_list_url, "{owner}", owner)
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

  defp get_prs({owner, repo, release}) when is_bitstring(owner) and is_bitstring(repo) and is_bitstring(release) do
    case fetch_pr_list({owner, repo}) do
      {:ok, pr_list} when is_list(pr_list) -> 
        {:ok, 
          Enum.filter(pr_list, fn pr ->
            Enum.any?(pr["labels"], fn label -> label["name"] === release end)
          end)
          |> Enum.map(fn pr ->
            %PR{
              title: pr["title"], # sad that pr.title won't work. These are different %{title: "title"} and %{"title" => "title"}
              number: pr["number"],
              user: pr["user"]["login"],
              labels: Enum.map(pr["labels"], fn label -> label["name"] end),
            }
          end)
        }
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

  def group_by_labels(prs, labels \\ []) when is_list(prs) and is_list(labels) do
    {_, empty_groups} = Enum.map_reduce(labels, %{}, fn label, groups ->
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
      },
    ]
  end

  def print(changes) do
    Enum.map(changes, fn c -> IO.puts c end)
  end
end

IO.puts "Hello from changeloggen.ex"