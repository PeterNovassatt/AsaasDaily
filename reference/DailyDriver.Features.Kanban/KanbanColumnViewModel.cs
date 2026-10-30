using System.Collections.Generic;
using DailyDriver.Atlassian.Dtos.Issue;
using DailyDriver.Features.Status;
using Microsoft.Maui.Graphics;

namespace DailyDriver.Features.Kanban;

public class KanbanColumnViewModel
{
	public string Status { get; }

	public List<AtlassianIssueDTO> Cards { get; }

	public Color Accent { get; }

	public Color Tint { get; }

	public string Icon { get; }

	public string Title => Status?.ToUpperInvariant() ?? string.Empty;

	public int Count => Cards.Count;

	public bool IsEmpty => Cards.Count == 0;

	public KanbanColumnViewModel(string status, List<AtlassianIssueDTO> cards)
	{
		Status = status;
		Cards = cards;
		Accent = StatusPalette.Accent(status);
		Tint = StatusPalette.Tint(status);
		Icon = KanbanBoard.IconFor(status);
	}
}
