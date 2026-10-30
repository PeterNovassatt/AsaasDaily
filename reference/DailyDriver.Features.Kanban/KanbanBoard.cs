using System;
using System.Collections.Generic;
using System.Linq;
using DailyDriver.Atlassian.Dtos.Issue;

namespace DailyDriver.Features.Kanban;

public static class KanbanBoard
{
	private static readonly string[] _columnOrder = new string[9] { "Backlog", "In Refinement", "In Preparation", "Prioritized", "To Do", "In Progress", "CODE REVIEW", "Product Review", "Rollout" };

	private static readonly Dictionary<string, string> _icons = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
	{
		["Backlog"] = "\udb84\ude74",
		["In Refinement"] = "\udb85\udd42",
		["In Preparation"] = "\udb85\udce6",
		["Prioritized"] = "\udb82\uddc7",
		["To Do"] = "\udb83\uddd0",
		["In Progress"] = "\udb82\udea0",
		["CODE REVIEW"] = "\udb80\udd74",
		["Product Review"] = "\udb83\udd05",
		["Rollout"] = "\udb85\udcdf"
	};

	public static string IconFor(string status)
	{
		string value;
		return (status != null && _icons.TryGetValue(status, out value)) ? value : "\udb82\udea2";
	}

	public static List<KanbanColumnViewModel> Build(List<AtlassianIssueDTO> cards)
	{
		List<AtlassianIssueDTO> source = cards ?? new List<AtlassianIssueDTO>();
		return (from card in source
			group card by card.Status ?? string.Empty into @group
			select new KanbanColumnViewModel(@group.Key, @group.ToList()) into column
			orderby IndexOf(column.Status)
			select column).ThenBy((KanbanColumnViewModel column) => column.Status, StringComparer.OrdinalIgnoreCase).ToList();
	}

	private static int IndexOf(string status)
	{
		int num = Array.FindIndex(_columnOrder, (string name) => string.Equals(name, status, StringComparison.OrdinalIgnoreCase));
		return (num < 0) ? _columnOrder.Length : num;
	}
}
