using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using DailyDriver.Atlassian.Dtos;
using DailyDriver.Atlassian.Dtos.Issue;
using DailyDriver.Atlassian.Dtos.Project;
using DailyDriver.Features.Configuration;
using Microsoft.Maui.Storage;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace DailyDriver.Atlassian.Request;

public class AtlassianRequestManager
{
	private static readonly HttpClient _httpClient = new HttpClient
	{
		Timeout = TimeSpan.FromSeconds(30L)
	};

	private const string FlaggedFieldFallback = "customfield_10023";

	private const string FlaggedFieldPreferenceKey = "flagged-field-id";

	private static Task<string> _flaggedFieldIdTask;

	private static readonly object _flaggedFieldLock = new object();

	private const int IssuePageSize = 200;

	public static async Task<List<AtlassianPersonDTO>> ListAssignableUsers(AtlassianConfigurationModel configuration)
	{
		string url = "https://asaasdev.atlassian.net/rest/api/3/user/assignable/search?project=" + Uri.EscapeDataString(configuration.Project) + "&maxResults=100";
		string content = await DoGet(configuration, url);
		if (content == null)
		{
			return null;
		}
		JArray usersArray = JsonConvert.DeserializeObject<JArray>(content);
		if (usersArray == null)
		{
			return null;
		}
		List<AtlassianPersonDTO> persons = new List<AtlassianPersonDTO>();
		foreach (JToken user in usersArray)
		{
			AtlassianPersonDTO atlassianPersonDTO = new AtlassianPersonDTO
			{
				Id = ((object)user[(object)"accountId"])?.ToString(),
				Name = ((object)user[(object)"displayName"])?.ToString()
			};
			JToken val = user[(object)"avatarUrls"];
			atlassianPersonDTO.AvatarUrl = ((val != null) ? ((object)val[(object)"48x48"])?.ToString() : null);
			JToken val2 = user[(object)"active"];
			atlassianPersonDTO.Active = val2 != null && val2.ToObject<bool>();
			persons.Add(atlassianPersonDTO);
		}
		return persons;
	}

	public static async IAsyncEnumerable<AtlassianJiraProjectDTO> ListAccessibleProjects(AtlassianConfigurationModel configuration)
	{
		int startAt = 0;
		while (true)
		{
			string url = $"https://asaasdev.atlassian.net/rest/api/3/project/search?orderBy=name&typeKey=software&status=live&maxResults={100}&startAt={startAt}";
			string content = await DoGet(configuration, url);
			if (content == null)
			{
				break;
			}
			JObject page = JsonConvert.DeserializeObject<JObject>(content);
			JToken obj = ((page != null) ? page["values"] : null);
			JArray values = (JArray)(object)((obj is JArray) ? obj : null);
			if (values == null || ((JContainer)values).Count == 0)
			{
				break;
			}
			foreach (JToken p in values)
			{
				JObject proj = (JObject)(object)((p is JObject) ? p : null);
				if (proj != null)
				{
					JToken val = proj["projectCategory"];
					JObject category = (JObject)(object)((val is JObject) ? val : null);
					AtlassianJiraProjectDTO atlassianJiraProjectDTO = new AtlassianJiraProjectDTO
					{
						Id = ((object)proj["id"])?.ToString(),
						Key = ((object)proj["key"])?.ToString(),
						Name = ((object)proj["name"])?.ToString()
					};
					atlassianJiraProjectDTO.Category = ((category == null) ? null : ((object)category["name"])?.ToString());
					yield return atlassianJiraProjectDTO;
				}
			}
			JToken val2 = page["isLast"];
			if (val2 == null || val2.ToObject<bool>())
			{
				break;
			}
			startAt += 100;
		}
	}

	public static async Task<List<AtlassianBoardDTO>> ListProjects(AtlassianConfigurationModel configuration)
	{
		string content = await DoGet(configuration, "https://asaasdev.atlassian.net/rest/agile/1.0/board?maxResults=15&negateLocationFiltering=false&orderBy=name&overrideFilterPermissions=true&projectLocation=" + configuration.Project + "&startAt=0");
		if (string.IsNullOrWhiteSpace(content))
		{
			return null;
		}
		AtlassianProjectResponseDTO recentProjects = JsonConvert.DeserializeObject<AtlassianProjectResponseDTO>(content);
		return recentProjects.Values;
	}

	private static Task<string> ResolveFlaggedFieldId(AtlassianConfigurationModel configuration)
	{
		lock (_flaggedFieldLock)
		{
			return _flaggedFieldIdTask ?? (_flaggedFieldIdTask = FetchFlaggedFieldId(configuration));
		}
	}

	private static async Task<string> FetchFlaggedFieldId(AtlassianConfigurationModel configuration)
	{
		string cached = Preferences.Get("flagged-field-id", string.Empty);
		if (!string.IsNullOrEmpty(cached))
		{
			return cached;
		}
		JArray val = JsonConvert.DeserializeObject<JArray>((await DoGet(configuration, "https://asaasdev.atlassian.net/rest/api/3/field")) ?? "[]");
		object obj;
		if (val == null)
		{
			obj = null;
		}
		else
		{
			JToken? val2 = ((IEnumerable<JToken>)val).FirstOrDefault((JToken field) => string.Equals(((object)field[(object)"name"])?.ToString(), "Flagged", StringComparison.OrdinalIgnoreCase));
			obj = ((val2 == null) ? null : ((object)val2[(object)"id"])?.ToString());
		}
		string id = (string)obj;
		if (string.IsNullOrEmpty(id))
		{
			return "customfield_10023";
		}
		Preferences.Set("flagged-field-id", id);
		return id;
	}

	public static Task<List<AtlassianIssueDTO>> ListSprintIssues(AtlassianConfigurationModel configuration, string boardId)
	{
		return ListSprintIssues(configuration, boardId, null);
	}

	public static async Task<List<AtlassianIssueDTO>> ListSprintIssues(AtlassianConfigurationModel configuration, string boardId, string assigneeId)
	{
		string flaggedFieldId = await ResolveFlaggedFieldId(configuration);
		string jqlText = (string.IsNullOrEmpty(assigneeId) ? "statusCategory != Done" : ("statusCategory != Done AND assignee = \"" + assigneeId + "\""));
		string jql = Uri.EscapeDataString(jqlText);
		string fields = "assignee,status,summary," + flaggedFieldId + ",issuetype,parent";
		string firstPage = await DoGet(configuration, PageUrl(0));
		if (firstPage == null)
		{
			return null;
		}
		JObject firstJson = JsonConvert.DeserializeObject<JObject>(firstPage);
		List<AtlassianIssueDTO> issues = ParseIssues(firstJson, flaggedFieldId);
		int? num;
		if (firstJson == null)
		{
			num = null;
		}
		else
		{
			JToken val = firstJson["total"];
			num = ((val != null) ? new int?(val.ToObject<int>()) : ((int?)null));
		}
		int total = num ?? issues.Count;
		if (total > 200)
		{
			IEnumerable<Task<string>> pages = from num3 in Enumerable.Range(1, (total - 1) / 200)
				select DoGet(configuration, PageUrl(num3 * 200));
			string[] array = await Task.WhenAll(pages);
			foreach (string page in array)
			{
				if (page != null)
				{
					issues.AddRange(ParseIssues(JsonConvert.DeserializeObject<JObject>(page), flaggedFieldId));
				}
			}
		}
		return issues;
		string PageUrl(int startAt)
		{
			return $"https://asaasdev.atlassian.net/rest/agile/1.0/board/{boardId}/issue?jql={jql}&fields={fields}&orderBy=rank&startAt={startAt}&maxResults={200}";
		}
	}

	private static List<AtlassianIssueDTO> ParseIssues(JObject page, string flaggedFieldId)
	{
		//IL_0141: Unknown result type (might be due to invalid IL or missing references)
		//IL_0146: Unknown result type (might be due to invalid IL or missing references)
		//IL_0148: Unknown result type (might be due to invalid IL or missing references)
		//IL_014c: Invalid comparison between Unknown and I4
		List<AtlassianIssueDTO> list = new List<AtlassianIssueDTO>();
		JToken obj = ((page != null) ? page["issues"] : null);
		JArray val = (JArray)(object)((obj is JArray) ? obj : null);
		if (val == null)
		{
			return list;
		}
		foreach (JToken item in val)
		{
			JObject val2 = (JObject)(object)((item is JObject) ? item : null);
			if (val2 == null)
			{
				continue;
			}
			JToken val3 = val2["fields"];
			JObject val4 = (JObject)(object)((val3 is JObject) ? val3 : null);
			JToken obj2 = ((val4 != null) ? val4["assignee"] : null);
			JObject val5 = (JObject)(object)((obj2 is JObject) ? obj2 : null);
			JToken obj3 = ((val4 != null) ? val4["status"] : null);
			JObject val6 = (JObject)(object)((obj3 is JObject) ? obj3 : null);
			JToken obj4 = ((val4 != null) ? val4["issuetype"] : null);
			JObject val7 = (JObject)(object)((obj4 is JObject) ? obj4 : null);
			JToken obj5 = ((val5 != null) ? val5["avatarUrls"] : null);
			JObject val8 = (JObject)(object)((obj5 is JObject) ? obj5 : null);
			JToken obj6 = ((val4 != null) ? val4["parent"] : null);
			JObject val9 = (JObject)(object)((obj6 is JObject) ? obj6 : null);
			JToken obj7 = ((val9 != null) ? val9["fields"] : null);
			JObject val10 = (JObject)(object)((obj7 is JObject) ? obj7 : null);
			JToken val11 = ((val4 != null) ? val4[flaggedFieldId] : null);
			if (1 == 0)
			{
			}
			JArray val12 = (JArray)(object)((val11 is JArray) ? val11 : null);
			bool flag;
			if (val12 == null)
			{
				JValue val13 = (JValue)(object)((val11 is JValue) ? val11 : null);
				if (val13 != null)
				{
					JTokenType type = ((JToken)val13).Type;
					if ((int)type != 10)
					{
						goto IL_0170;
					}
					flag = false;
				}
				else
				{
					if (val11 != null)
					{
						goto IL_0170;
					}
					flag = false;
				}
			}
			else
			{
				flag = ((JContainer)val12).Count > 0;
			}
			goto IL_0175;
			IL_0170:
			flag = true;
			goto IL_0175;
			IL_0175:
			if (1 == 0)
			{
			}
			bool isFlagged = flag;
			AtlassianIssueDTO atlassianIssueDTO = new AtlassianIssueDTO
			{
				Key = ((object)val2["key"])?.ToString(),
				Summary = ((val4 == null) ? null : ((object)val4["summary"])?.ToString()),
				Status = ((val6 == null) ? null : ((object)val6["name"])?.ToString()),
				IssueType = ((val7 == null) ? null : ((object)val7["name"])?.ToString()),
				AssigneeId = (((val5 == null) ? null : ((object)val5["accountId"])?.ToString()) ?? ((val5 == null) ? null : ((object)val5["key"])?.ToString())),
				AssigneeName = ((val5 == null) ? null : ((object)val5["displayName"])?.ToString()),
				AssigneeAvatarUrl = ((val8 == null) ? null : ((object)val8["48x48"])?.ToString()),
				ParentKey = ((val9 == null) ? null : ((object)val9["key"])?.ToString()),
				ParentSummary = ((val10 == null) ? null : ((object)val10["summary"])?.ToString())
			};
			JToken obj8 = ((val10 != null) ? val10["issuetype"] : null);
			JToken obj9 = ((obj8 is JObject) ? obj8 : null);
			atlassianIssueDTO.ParentType = ((obj9 == null) ? null : ((object)((JObject)obj9)["name"])?.ToString());
			atlassianIssueDTO.IsFlagged = isFlagged;
			list.Add(atlassianIssueDTO);
		}
		return list;
	}

	private static async Task<string> DoGet(AtlassianConfigurationModel configuration, string url)
	{
		HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Get, url)
		{
			Headers = { { "Accept", "application/json" } }
		};
		if (!string.IsNullOrEmpty(configuration.Email) && !string.IsNullOrEmpty(configuration.ApiToken))
		{
			string credentials = Convert.ToBase64String(Encoding.UTF8.GetBytes(configuration.Email + ":" + configuration.ApiToken));
			request.Headers.Add("Authorization", "Basic " + credentials);
		}
		else
		{
			if (string.IsNullOrEmpty(configuration.Cookie))
			{
				return null;
			}
			request.Headers.Add("Cookie", "tenant.session.token=" + configuration.Cookie);
		}
		HttpResponseMessage response = await _httpClient.SendAsync(request);
		if (response.StatusCode != HttpStatusCode.OK)
		{
			return null;
		}
		return await response.Content.ReadAsStringAsync();
	}
}
