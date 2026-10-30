using System.Collections.Generic;
using DailyDriver.Atlassian.Dtos.Issue;

namespace DailyDriver;

public record SpeakingPersonEntry(AtlassianPersonDTO Person, List<AtlassianIssueDTO> Issues);
