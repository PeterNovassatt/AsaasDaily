using System;

namespace DailyDriver.Atlassian.Dtos.Issue;

public class AtlassianIssueDTO
{
	public string Key { get; set; }

	public string Summary { get; set; }

	public string Status { get; set; }

	public string IssueType { get; set; }

	public string AssigneeId { get; set; }

	public string AssigneeName { get; set; }

	public string AssigneeAvatarUrl { get; set; }

	public bool IsTriggerCard { get; set; }

	public string ParentKey { get; set; }

	public string ParentSummary { get; set; }

	public string ParentType { get; set; }

	public bool HasParent => !string.IsNullOrEmpty(ParentKey);

	public string ParentLabel => HasParent ? (ParentKey + " · " + ParentSummary) : string.Empty;

	public bool IsEpic => IssueType?.Contains("Epic", StringComparison.OrdinalIgnoreCase) ?? false;

	public bool IsFlagged { get; set; }
}
