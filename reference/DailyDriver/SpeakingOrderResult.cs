using System.Collections.Generic;
using DailyDriver.Atlassian.Dtos.Issue;

namespace DailyDriver;

public record SpeakingOrderResult(List<SpeakingPersonEntry> Speakers, List<AtlassianIssueDTO> UnassignedIssues);
