using System;
using System.Collections.Generic;
using System.Linq;
using DailyDriver.Atlassian.Dtos.Issue;
using DailyDriver.Features.Kanban;
using Microsoft.Maui.Controls;

namespace DailyDriver;

public class PersonViewModel : BaseViewModel
{
	private ImageSource _source;

	private string _name;

	private bool _talked;

	private double _opacity = 1.0;

	private string _positionLabel = string.Empty;

	private List<AtlassianIssueDTO> _cards = new List<AtlassianIssueDTO>();

	public ImageSource Source
	{
		get
		{
			return _source;
		}
		set
		{
			SetProperty(ref _source, value, "Source");
		}
	}

	public string Name
	{
		get
		{
			return _name;
		}
		set
		{
			SetProperty(ref _name, value, "Name");
		}
	}

	public string AssigneeId { get; set; }

	public bool Talked
	{
		get
		{
			return _talked;
		}
		set
		{
			SetProperty(ref _talked, value, "Talked");
		}
	}

	public double Opacity
	{
		get
		{
			return _opacity;
		}
		set
		{
			SetProperty(ref _opacity, value, "Opacity");
		}
	}

	public string PositionLabel
	{
		get
		{
			return _positionLabel;
		}
		set
		{
			SetProperty(ref _positionLabel, value, "PositionLabel");
		}
	}

	public List<AtlassianIssueDTO> Cards
	{
		get
		{
			return _cards;
		}
		set
		{
			List<AtlassianIssueDTO> source = value ?? new List<AtlassianIssueDTO>();
			HashSet<string> parentKeys = (from card in source
				where card.HasParent
				select card.ParentKey).ToHashSet(StringComparer.OrdinalIgnoreCase);
			List<AtlassianIssueDTO> source2 = source.Where((AtlassianIssueDTO card) => !parentKeys.Contains(card.Key)).ToList();
			CodeReviewCards = source2.Where((AtlassianIssueDTO c) => !c.IsEpic && string.Equals(c.Status, "CODE REVIEW", StringComparison.OrdinalIgnoreCase)).ToList();
			InProgressCards = source2.Where((AtlassianIssueDTO c) => !c.IsEpic && string.Equals(c.Status, "IN PROGRESS", StringComparison.OrdinalIgnoreCase)).ToList();
			TodoCards = source2.Where((AtlassianIssueDTO c) => !c.IsEpic && !string.Equals(c.Status, "CODE REVIEW", StringComparison.OrdinalIgnoreCase) && !string.Equals(c.Status, "IN PROGRESS", StringComparison.OrdinalIgnoreCase)).ToList();
			EpicCards = source2.Where((AtlassianIssueDTO c) => c.IsEpic).ToList();
			FlaggedCards = source2.Where((AtlassianIssueDTO c) => !c.IsEpic && c.IsFlagged).ToList();
			_cards = CodeReviewCards.Concat(InProgressCards).Concat(TodoCards).Concat(EpicCards)
				.ToList();
			Columns = KanbanBoard.Build(_cards);
			NotifyCardsChanged();
		}
	}

	public List<KanbanColumnViewModel> Columns { get; private set; } = new List<KanbanColumnViewModel>();

	public List<AtlassianIssueDTO> CodeReviewCards { get; private set; } = new List<AtlassianIssueDTO>();

	public List<AtlassianIssueDTO> InProgressCards { get; private set; } = new List<AtlassianIssueDTO>();

	public List<AtlassianIssueDTO> TodoCards { get; private set; } = new List<AtlassianIssueDTO>();

	public List<AtlassianIssueDTO> EpicCards { get; private set; } = new List<AtlassianIssueDTO>();

	public List<AtlassianIssueDTO> FlaggedCards { get; private set; } = new List<AtlassianIssueDTO>();

	public bool HasCards => _cards.Count > 0;

	public bool HasCodeReviewCards => CodeReviewCards.Count > 0;

	public bool HasInProgressCards => InProgressCards.Count > 0;

	public bool HasTodoCards => TodoCards.Count > 0;

	public bool HasEpicCards => EpicCards.Count > 0;

	public bool HasFlaggedCards => FlaggedCards.Count > 0;

	public int CardCount => _cards.Count;

	public int CodeReviewCount => CodeReviewCards.Count;

	public int InProgressCount => InProgressCards.Count;

	public int FlaggedCount => FlaggedCards.Count;

	public string CodeReviewHeader => $"Code Review ({CodeReviewCards.Count})";

	public string InProgressHeader => $"In Progress ({InProgressCards.Count})";

	public string TodoHeader => $"To Do ({TodoCards.Count})";

	public string EpicHeader => $"Épicos ({EpicCards.Count})";

	public string CodeReviewBadge => $"{CodeReviewCards.Count} CR";

	public string InProgressBadge => $"{InProgressCards.Count} IP";

	public string TodoBadge => $"{TodoCards.Count} To Do";

	public string FlaggedBadge => $"{FlaggedCards.Count} ⚑";

	public string CardSummary
	{
		get
		{
			int count = _cards.Count;
			string result;
			switch (count)
			{
			case 0:
				return string.Empty;
			default:
				result = $"{count} cards";
				break;
			case 1:
				result = "1 card";
				break;
			}
			return result;
		}
	}

	private void NotifyCardsChanged()
	{
		string[] array = new string[26]
		{
			"Cards", "CodeReviewCards", "InProgressCards", "TodoCards", "Columns", "EpicCards", "FlaggedCards", "HasCards", "HasCodeReviewCards", "HasInProgressCards",
			"HasTodoCards", "HasEpicCards", "HasFlaggedCards", "CardCount", "CodeReviewCount", "InProgressCount", "FlaggedCount", "CodeReviewHeader", "InProgressHeader", "TodoHeader",
			"EpicHeader", "CodeReviewBadge", "InProgressBadge", "TodoBadge", "FlaggedBadge", "CardSummary"
		};
		foreach (string propertyName in array)
		{
			OnPropertyChanged(propertyName);
		}
	}

	protected override void OnPropertyChanged(string propertyName = null)
	{
		base.OnPropertyChanged(propertyName);
		if (propertyName == "Talked")
		{
			Opacity = (Talked ? 0.54 : 1.0);
		}
	}
}
