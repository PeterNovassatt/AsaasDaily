using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using DailyDriver.Atlassian.Dtos;
using DailyDriver.Atlassian.Dtos.Issue;
using DailyDriver.Atlassian.Dtos.Project;
using DailyDriver.Atlassian.Request;
using DailyDriver.Features.Configuration;
using Microsoft.Maui.Storage;
using Newtonsoft.Json;

namespace DailyDriver;

public class AtlassianService
{
	public static IAsyncEnumerable<AtlassianJiraProjectDTO> ListAccessibleProjects(AtlassianConfigurationModel configuration)
	{
		return AtlassianRequestManager.ListAccessibleProjects(configuration);
	}

	public static async Task<List<AtlassianIssueDTO>> ListIssuesForAssignee(AtlassianConfigurationModel configuration, string assigneeId)
	{
		if (string.IsNullOrEmpty(assigneeId))
		{
			return null;
		}
		List<AtlassianBoardDTO> boards = await ListBoards(configuration);
		if (boards == null)
		{
			return null;
		}
		List<AtlassianIssueDTO> issues = new List<AtlassianIssueDTO>();
		object issueLock = new object();
		await Task.WhenAll(boards.Select((AtlassianBoardDTO board) => Task.Run(async () =>
		{
			List<AtlassianIssueDTO> boardIssues = await AtlassianRequestManager.ListSprintIssues(configuration, board.Id.ToString(), assigneeId);
			if (boardIssues != null)
			{
				lock (issueLock)
				{
					issues.AddRange(boardIssues);
				}
			}
		})));
		return (from issue in issues
			group issue by issue.Key into @group
			select @group.First()).ToList();
	}

	public static async Task<List<AtlassianPersonDTO>> ListActiveAssignees(AtlassianConfigurationModel configuration)
	{
		List<AtlassianBoardDTO> boards = await ListBoards(configuration);
		if (boards == null)
		{
			return null;
		}
		List<AtlassianIssueDTO> allIssues = new List<AtlassianIssueDTO>();
		object issueLock = new object();
		await Task.WhenAll(boards.Select((AtlassianBoardDTO board) => Task.Run(async () =>
		{
			List<AtlassianIssueDTO> boardIssues = await AtlassianRequestManager.ListSprintIssues(configuration, board.Id.ToString());
			if (boardIssues != null)
			{
				lock (issueLock)
				{
					allIssues.AddRange(boardIssues);
				}
			}
		})));
		Dictionary<string, AtlassianPersonDTO> assignees = new Dictionary<string, AtlassianPersonDTO>();
		foreach (AtlassianIssueDTO issue in allIssues)
		{
			if (!string.IsNullOrEmpty(issue.AssigneeId) && !assignees.ContainsKey(issue.AssigneeId))
			{
				assignees[issue.AssigneeId] = new AtlassianPersonDTO
				{
					Id = issue.AssigneeId,
					Name = issue.AssigneeName,
					AvatarUrl = issue.AssigneeAvatarUrl,
					Active = true
				};
			}
		}
		return assignees.Values.OrderBy((AtlassianPersonDTO p) => p.Name).ToList();
	}

	public static async Task<List<AtlassianBoardDTO>> ListBoards(AtlassianConfigurationModel configuration)
	{
		string[] projectKeys = ParseProjectKeys(configuration.Project);
		if (projectKeys.Length == 0)
		{
			return null;
		}
		string cacheKey = "boards:" + configuration.Project;
		string cachedJson = Preferences.Get(cacheKey, string.Empty);
		if (!string.IsNullOrEmpty(cachedJson))
		{
			List<AtlassianBoardDTO> cached = JsonConvert.DeserializeObject<List<AtlassianBoardDTO>>(cachedJson);
			if (cached != null && cached.Count > 0)
			{
				Task.Run(() => FetchAndCacheBoards(configuration, projectKeys, cacheKey));
				return cached;
			}
		}
		return await FetchAndCacheBoards(configuration, projectKeys, cacheKey);
	}

	private static async Task<List<AtlassianBoardDTO>> FetchAndCacheBoards(AtlassianConfigurationModel configuration, string[] projectKeys, string cacheKey)
	{
		List<AtlassianBoardDTO> allBoards = new List<AtlassianBoardDTO>();
		await Task.WhenAll(projectKeys.Select((string key) => Task.Run(async () =>
		{
			List<AtlassianBoardDTO> boards = await AtlassianRequestManager.ListProjects(CloneWithProject(configuration, key));
			if (boards != null)
			{
				lock (allBoards)
				{
					allBoards.AddRange(boards);
				}
			}
		})));
		if (allBoards.Count == 0)
		{
			return null;
		}
		Preferences.Set(cacheKey, JsonConvert.SerializeObject((object)allBoards));
		return allBoards;
	}

	private static string[] ParseProjectKeys(string project)
	{
		return project?.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries) ?? Array.Empty<string>();
	}

	private static AtlassianConfigurationModel CloneWithProject(AtlassianConfigurationModel source, string project)
	{
		return new AtlassianConfigurationModel
		{
			Email = source.Email,
			ApiToken = source.ApiToken,
			Cookie = source.Cookie,
			Project = project
		};
	}

	public static void CachePersonList(List<AtlassianPersonDTO> persons)
	{
		string text = JsonConvert.SerializeObject((object)persons);
		Preferences.Set("persons", text);
	}

	public static List<AtlassianPersonDTO> ListCachedPersons()
	{
		string text = Preferences.Get("persons", string.Empty);
		if (string.IsNullOrEmpty(text))
		{
			return null;
		}
		return JsonConvert.DeserializeObject<List<AtlassianPersonDTO>>(text);
	}

	public static void CacheProjectList(List<AtlassianJiraProjectDTO> projects)
	{
		string text = JsonConvert.SerializeObject((object)projects);
		Preferences.Set("jira-projects", text);
	}

	public static List<AtlassianJiraProjectDTO> ListCachedProjects()
	{
		string text = Preferences.Get("jira-projects", string.Empty);
		if (string.IsNullOrEmpty(text))
		{
			return null;
		}
		return JsonConvert.DeserializeObject<List<AtlassianJiraProjectDTO>>(text);
	}

	public static AtlassianConfigurationModel GetConfiguration()
	{
		string text = Preferences.Get("new-configuration", string.Empty);
		if (string.IsNullOrEmpty(text))
		{
			return null;
		}
		return JsonConvert.DeserializeObject<AtlassianConfigurationModel>(text);
	}

	public static void SaveConfiguration(AtlassianConfigurationModel atlassianConfigurationModel)
	{
		string text = JsonConvert.SerializeObject((object)atlassianConfigurationModel);
		Preferences.Set("new-configuration", text);
	}

	public static void SaveSpeech(bool enabled)
	{
		Preferences.Set("speech-enabled", enabled);
	}

	public static bool IsSpeechEnabled()
	{
		return Preferences.Get("speech-enabled", false);
	}

	public static bool IsConfigured()
	{
		AtlassianConfigurationModel configuration = GetConfiguration();
		if (configuration == null)
		{
			return false;
		}
		bool flag = !string.IsNullOrEmpty(configuration.Email) && !string.IsNullOrEmpty(configuration.ApiToken);
		bool flag2 = !string.IsNullOrEmpty(configuration.Cookie);
		return flag | flag2;
	}

	public static async Task<SpeakingOrderResult> BuildSpeakingOrder(AtlassianConfigurationModel config, List<AtlassianPersonDTO> cachedPersons)
	{
		List<AtlassianBoardDTO> boards = await ListBoards(config);
		if (boards == null)
		{
			return null;
		}
		List<AtlassianIssueDTO> allIssues = new List<AtlassianIssueDTO>();
		object issueLock = new object();
		await Task.WhenAll(boards.Select((AtlassianBoardDTO board) => Task.Run(async () =>
		{
			List<AtlassianIssueDTO> boardIssues = await AtlassianRequestManager.ListSprintIssues(config, board.Id.ToString());
			if (boardIssues != null)
			{
				lock (issueLock)
				{
					allIssues.AddRange(boardIssues);
				}
			}
		})));
		List<AtlassianPersonDTO> activePersons = cachedPersons?.Where((AtlassianPersonDTO p) => p.Active && p.IsChecked).ToList() ?? new List<AtlassianPersonDTO>();
		List<AtlassianIssueDTO> codeReviewIssues = allIssues.Where((AtlassianIssueDTO i) => !i.IsEpic && string.Equals(i.Status, "CODE REVIEW", StringComparison.OrdinalIgnoreCase)).ToList();
		List<AtlassianIssueDTO> inProgressIssues = allIssues.Where((AtlassianIssueDTO i) => !i.IsEpic && string.Equals(i.Status, "IN PROGRESS", StringComparison.OrdinalIgnoreCase)).ToList();
		List<AtlassianIssueDTO> unassignedIssues = (from i in codeReviewIssues.Concat(inProgressIssues)
			where string.IsNullOrEmpty(i.AssigneeId)
			select i).ToList();
		Dictionary<string, List<AtlassianIssueDTO>> allIssuesByAssignee = (from i in allIssues
			where !string.IsNullOrEmpty(i.AssigneeId)
			group i by i.AssigneeId).ToDictionary((IGrouping<string, AtlassianIssueDTO> g) => g.Key, (IGrouping<string, AtlassianIssueDTO> g) => g.ToList());
		List<SpeakingPersonEntry> orderedSpeakers = new List<SpeakingPersonEntry>();
		HashSet<string> addedAssigneeIds = new HashSet<string>();
		AddSpeakersFromIssues(codeReviewIssues, activePersons, allIssuesByAssignee, orderedSpeakers, addedAssigneeIds);
		AddSpeakersFromIssues(inProgressIssues, activePersons, allIssuesByAssignee, orderedSpeakers, addedAssigneeIds);
		List<AtlassianPersonDTO> remaining = (from _ in activePersons
			where !addedAssigneeIds.Contains(_.Id)
			orderby Guid.NewGuid()
			select _).ToList();
		foreach (AtlassianPersonDTO person in remaining)
		{
			List<AtlassianIssueDTO> personIssues = allIssuesByAssignee.GetValueOrDefault(person.Id, new List<AtlassianIssueDTO>());
			orderedSpeakers.Add(new SpeakingPersonEntry(person, personIssues));
		}
		return new SpeakingOrderResult(orderedSpeakers, unassignedIssues);
	}

	private static void AddSpeakersFromIssues(List<AtlassianIssueDTO> issues, List<AtlassianPersonDTO> activePersons, Dictionary<string, List<AtlassianIssueDTO>> allIssuesByAssignee, List<SpeakingPersonEntry> orderedSpeakers, HashSet<string> addedIds)
	{
		foreach (AtlassianIssueDTO issue in issues)
		{
			if (!string.IsNullOrEmpty(issue.AssigneeId) && !addedIds.Contains(issue.AssigneeId))
			{
				AtlassianPersonDTO atlassianPersonDTO = activePersons.FirstOrDefault((AtlassianPersonDTO p) => p.Id == issue.AssigneeId) ?? activePersons.FirstOrDefault((AtlassianPersonDTO p) => string.Equals(p.Name, issue.AssigneeName, StringComparison.OrdinalIgnoreCase));
				if (atlassianPersonDTO != null)
				{
					issue.IsTriggerCard = true;
					addedIds.Add(issue.AssigneeId);
					List<AtlassianIssueDTO> valueOrDefault = allIssuesByAssignee.GetValueOrDefault(atlassianPersonDTO.Id, new List<AtlassianIssueDTO>());
					orderedSpeakers.Add(new SpeakingPersonEntry(atlassianPersonDTO, valueOrDefault));
				}
			}
		}
	}
}
