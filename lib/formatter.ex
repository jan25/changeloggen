defmodule Formatter do
   
  @output_tmpl """
  # {release}

  {changes}
  """

  @grouped_changes_tmpl """
  ## {label}
  {changes}
  """

  def no_grouping(prs, release) when is_list(prs) and is_bitstring(release) do
    prs_string = Enum.reduce(prs, "", fn pr, acc -> acc <> "* #{pr}\n" end)

    String.replace(@output_tmpl, "{release}", release)
    |> String.replace("{changes}", prs_string)
  end

  def grouped(groups, release) when is_map(groups) and is_bitstring(release) do
    groups_strs = Map.to_list(groups)
    |> Enum.map(&group_tmpl/1)
    |> Enum.filter(fn tmpl -> tmpl !== "" end)

    case groups_strs do
        [] ->
        "No PRs found matching supplied labels"

        _ ->
        changes = Enum.reduce(groups_strs, "", fn groups_str, acc -> acc <> groups_str end)

        String.replace(@output_tmpl, "{release}", release)
        |> String.replace("{changes}", changes)
    end
  end

  defp group_tmpl({_, []}), do: ""

  defp group_tmpl({label, prs}) when is_bitstring(label) and is_list(prs) do
    prs_string = Enum.reduce(prs, "", fn pr, acc -> acc <> "* #{pr}\n" end)

    String.replace(@grouped_changes_tmpl, "{label}", label)
    |> String.replace("{changes}", prs_string)
  end

end