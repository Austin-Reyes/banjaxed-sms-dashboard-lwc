public with sharing class BanjaxedReportController {
    
    @AuraEnabled(cacheable=true)
    public static List<TeamUnresolvedCount> getTeamUnresolvedCounts() {
        List<TeamUnresolvedCount> results = new List<TeamUnresolvedCount>();
        
        try {
            // Use matter-centric approach: query matters with unresolved conversations
            // This avoids the global record limit issue by being more targeted
            // In test context, use a smaller limit to avoid hitting governor limits
            Integer queryLimit = Test.isRunningTest() ? 1000 : 50000;
            
            Map<String, Set<Id>> teamToMatters = new Map<String, Set<Id>>();
            
            // Query matters that have unresolved conversations
            // This is more efficient than processing all conversations or messages globally
            String query = 'SELECT Id, litify_pm__Default_Matter_Team__r.Name ' +
                          'FROM litify_pm__Matter__c ' +
                          'WHERE litify_pm__Status__c = \'Open\' ' +
                          'AND litify_pm__Default_Matter_Team__r.Name != null ' +
                          'AND Id IN (' +
                          '    SELECT Matter__c ' +
                          '    FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                          '    WHERE banjaxed_cm__Message__r.banjaxed_cm__Conversation__r.banjaxed_cm__Resolved__c = false ' +
                          '    AND banjaxed_cm__Message__c != null ' +
                          '    AND Matter__c != null' +
                          ') ' +
                          'LIMIT ' + queryLimit;
            
            for (litify_pm__Matter__c matter : Database.query(query)) {
                String teamName = matter.litify_pm__Default_Matter_Team__r.Name;
                if (!teamToMatters.containsKey(teamName)) {
                    teamToMatters.put(teamName, new Set<Id>());
                }
                teamToMatters.get(teamName).add(matter.Id);
            }
            
            // Convert to results
            for (String teamName : teamToMatters.keySet()) {
                results.add(new TeamUnresolvedCount(teamName, teamToMatters.get(teamName).size()));
            }
            
            // Sort by count descending
            results.sort();
        } catch (Exception e) {
            System.debug('Error in getTeamUnresolvedCounts: ' + e.getMessage());
        }
        
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<StageBreakdown> getTeamStageBreakdown(String teamName) {
        List<StageBreakdown> results = new List<StageBreakdown>();
        
        try {
            // Use the canonical Banjaxed query pattern to find unresolved matters for specific team
            // In test context, use a smaller limit to avoid hitting governor limits
            Integer queryLimit = Test.isRunningTest() ? 1000 : 10000;
            
            Map<String, Set<Id>> stageToMatters = new Map<String, Set<Id>>();
            
            // Direct query using the correct Banjaxed data model, filtered by team
            String query = 'SELECT Matter__c, Matter__r.litify_pm__Matter_Stage_Activity__r.Name ' +
                          'FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                          'WHERE banjaxed_cm__Message__r.banjaxed_cm__Conversation__r.banjaxed_cm__Resolved__c = false ' +
                          'AND banjaxed_cm__Message__c != null ' +
                          'AND Matter__c != null ' +
                          'AND Matter__r.litify_pm__Status__c = \'Open\' ' +
                          'AND Matter__r.litify_pm__Default_Matter_Team__r.Name = :teamName ' +
                          'LIMIT ' + queryLimit;
            
            for (banjaxed_cm__Banjaxed_Matter_Intake_Message__c matterMsg : Database.query(query)) {
                String stageName = matterMsg.Matter__r.litify_pm__Matter_Stage_Activity__r.Name;
                if (stageName == null) stageName = 'No Stage';
                
                if (!stageToMatters.containsKey(stageName)) {
                    stageToMatters.put(stageName, new Set<Id>());
                }
                stageToMatters.get(stageName).add(matterMsg.Matter__c);
            }
            
            // Convert map to results
            for (String stageName : stageToMatters.keySet()) {
                results.add(new StageBreakdown(
                    stageName,
                    stageToMatters.get(stageName).size()
                ));
            }
            
            // Sort by count descending
            results.sort();
            
        } catch (Exception e) {
            System.debug('Error in getTeamStageBreakdown: ' + e.getMessage());
        }
        
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MatterDetail> getStageMatters(String teamName, String stageName) {
        List<MatterDetail> results = new List<MatterDetail>();
        
        try {
            // Use the canonical Banjaxed query pattern to find unresolved matters for specific team and stage
            // In test context, use a smaller limit to avoid hitting governor limits
            Integer queryLimit = Test.isRunningTest() ? 1000 : 10000;
            
            Map<Id, MatterDetail> matterDetailsMap = new Map<Id, MatterDetail>();
            
            // Direct query using the correct Banjaxed data model, filtered by team and stage
            String query = 'SELECT Matter__c, Matter__r.litify_pm__Display_Name__c, ' +
                          'Matter__r.litify_pm__Status__c, Matter__r.litify_pm__Client__r.Name, ' +
                          'banjaxed_cm__Message__r.banjaxed_cm__SentDate__c, ' +
                          'banjaxed_cm__Message__r.banjaxed_cm__Message_Body__c ' +
                          'FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                          'WHERE banjaxed_cm__Message__r.banjaxed_cm__Conversation__r.banjaxed_cm__Resolved__c = false ' +
                          'AND banjaxed_cm__Message__c != null ' +
                          'AND Matter__c != null ' +
                          'AND Matter__r.litify_pm__Status__c = \'Open\' ' +
                          'AND Matter__r.litify_pm__Default_Matter_Team__r.Name = :teamName ' +
                          'AND Matter__r.litify_pm__Matter_Stage_Activity__r.Name = :stageName ' +
                          'ORDER BY banjaxed_cm__Message__r.banjaxed_cm__SentDate__c DESC ' +
                          'LIMIT ' + queryLimit;
            
            for (banjaxed_cm__Banjaxed_Matter_Intake_Message__c matterMsg : Database.query(query)) {
                Id matterId = matterMsg.Matter__c;
                
                // Initialize or update matter detail
                if (!matterDetailsMap.containsKey(matterId)) {
                    matterDetailsMap.put(matterId, new MatterDetail(
                        matterId,
                        matterMsg.Matter__r.litify_pm__Display_Name__c,
                        matterMsg.Matter__r.litify_pm__Status__c,
                        matterMsg.Matter__r.litify_pm__Client__r.Name,
                        0, // Will be counted below
                        null, // Will be set below
                        null  // Will be set below
                    ));
                }
                
                MatterDetail existing = matterDetailsMap.get(matterId);
                existing.unresolvedCount++;
                
                // Update with latest message if this is newer or first message
                DateTime msgSentDate = matterMsg.banjaxed_cm__Message__r.banjaxed_cm__SentDate__c;
                if (existing.lastMessageDate == null || (msgSentDate != null && msgSentDate > existing.lastMessageDate)) {
                    existing.lastMessageDate = msgSentDate;
                    existing.lastMessageBody = matterMsg.banjaxed_cm__Message__r.banjaxed_cm__Message_Body__c;
                }
            }
            
            // Convert map to list and sort by count descending, then by date descending
            results.addAll(matterDetailsMap.values());
            results.sort(new MatterDetailComparator());
        } catch (Exception e) {
            System.debug('Error in getStageMatters: ' + e.getMessage());
        }
        
        return results;
    }
    
    public class TeamUnresolvedCount implements Comparable {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Integer count { get; set; }
        
        public TeamUnresolvedCount(String name, Integer count) {
            this.name = name;
            this.count = count;
        }
        
        public Integer compareTo(Object other) {
            TeamUnresolvedCount otherCount = (TeamUnresolvedCount)other;
            // Sort by count descending
            return otherCount.count - this.count;
        }
    }
    
    public class StageBreakdown implements Comparable {
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public Integer count { get; set; }
        
        public StageBreakdown(String stageName, Integer count) {
            this.stageName = stageName;
            this.count = count;
        }
        
        public Integer compareTo(Object other) {
            StageBreakdown otherBreakdown = (StageBreakdown)other;
            // Sort by count descending
            return otherBreakdown.count - this.count;
        }
    }
    
    public class MatterDetail {
        @AuraEnabled public String matterId { get; set; }
        @AuraEnabled public String matterName { get; set; }
        @AuraEnabled public String matterStatus { get; set; }
        @AuraEnabled public String clientName { get; set; }
        @AuraEnabled public Integer unresolvedCount { get; set; }
        @AuraEnabled public DateTime lastMessageDate { get; set; }
        @AuraEnabled public String lastMessageBody { get; set; }
        
        public MatterDetail(String matterId, String matterName, String matterStatus, 
                           String clientName, Integer unresolvedCount, DateTime lastMessageDate, String lastMessageBody) {
            this.matterId = matterId;
            this.matterName = matterName;
            this.matterStatus = matterStatus;
            this.clientName = clientName;
            this.unresolvedCount = unresolvedCount;
            this.lastMessageDate = lastMessageDate;
            this.lastMessageBody = lastMessageBody;
        }
    }
    
    // Comparator for sorting MatterDetail objects
    public class MatterDetailComparator implements Comparator<MatterDetail> {
        public Integer compare(MatterDetail a, MatterDetail b) {
            // First sort by unresolved count descending
            if (a.unresolvedCount != b.unresolvedCount) {
                return b.unresolvedCount - a.unresolvedCount;
            }
            // Then sort by last message date descending (newer first)
            if (a.lastMessageDate != b.lastMessageDate) {
                return a.lastMessageDate > b.lastMessageDate ? -1 : 1;
            }
            return 0;
        }
    }
}