public with sharing class BanjaxedReportController {
    
    @AuraEnabled(cacheable=true)
    public static List<TeamUnresolvedCount> getTeamUnresolvedCounts() {
        List<TeamUnresolvedCount> results = new List<TeamUnresolvedCount>();
        
        String query = 'SELECT Matter__r.litify_pm__Default_Matter_Team__r.Name teamName, COUNT(Id) unresolvedCount ' +
                       'FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                       'WHERE banjaxed_cm__Status__c = \'RECEIVED\' ' +
                       'AND CreatedDate = LAST_N_DAYS:30 ' +
                       'AND Matter__r.litify_pm__Default_Matter_Team__r.Name != null ' +
                       'GROUP BY Matter__r.litify_pm__Default_Matter_Team__r.Name ' +
                       'ORDER BY COUNT(Id) DESC';
        
        try {
            for (AggregateResult ar : Database.query(query)) {
                results.add(new TeamUnresolvedCount(
                    (String) ar.get('teamName'),
                    (Integer) ar.get('unresolvedCount')
                ));
            }
        } catch (Exception e) {
            System.debug('Error in getTeamUnresolvedCounts: ' + e.getMessage());
        }
        
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<StageBreakdown> getTeamStageBreakdown(String teamName) {
        List<StageBreakdown> results = new List<StageBreakdown>();
        
        String query = 'SELECT Matter__r.litify_pm__Matter_Stage_Activity__r.Name stageName, COUNT(Id) stageCount ' +
                       'FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                       'WHERE banjaxed_cm__Status__c = \'RECEIVED\' ' +
                       'AND CreatedDate = LAST_N_DAYS:30 ' +
                       'AND Matter__r.litify_pm__Default_Matter_Team__r.Name = :teamName ' +
                       'AND Matter__r.litify_pm__Matter_Stage_Activity__r.Name != null ' +
                       'GROUP BY Matter__r.litify_pm__Matter_Stage_Activity__r.Name ' +
                       'ORDER BY COUNT(Id) DESC';
        
        try {
            for (AggregateResult ar : Database.query(query)) {
                results.add(new StageBreakdown(
                    (String) ar.get('stageName'),
                    (Integer) ar.get('stageCount')
                ));
            }
        } catch (Exception e) {
            System.debug('Error in getTeamStageBreakdown: ' + e.getMessage());
        }
        
        return results;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<MatterDetail> getStageMatters(String teamName, String stageName) {
        List<MatterDetail> results = new List<MatterDetail>();
        
        String query = 'SELECT Matter__r.Id matterId, ' +
                       'Matter__r.litify_pm__Display_Name__c matterDisplayName, ' +
                       'Matter__r.litify_pm__Status__c matterStatus, ' +
                       'Matter__r.litify_pm__Client__r.Name clientName, ' +
                       'COUNT(Id) unresolvedCount, MAX(CreatedDate) lastMessageDate ' +
                       'FROM banjaxed_cm__Banjaxed_Matter_Intake_Message__c ' +
                       'WHERE banjaxed_cm__Status__c = \'RECEIVED\' ' +
                       'AND CreatedDate = LAST_N_DAYS:30 ' +
                       'AND Matter__r.litify_pm__Default_Matter_Team__r.Name = :teamName ' +
                       'AND Matter__r.litify_pm__Matter_Stage_Activity__r.Name = :stageName ' +
                       'AND Matter__r.litify_pm__Status__c != \'Closed\' ' +
                       'AND Matter__r.litify_pm__Status__c != \'Rejected\' ' +
                       'AND Matter__r.litify_pm__Status__c != \'Closed - Rejected\' ' +
                       'GROUP BY Matter__r.Id, Matter__r.litify_pm__Display_Name__c, Matter__r.litify_pm__Status__c, ' +
                       'Matter__r.litify_pm__Client__r.Name ' +
                       'ORDER BY COUNT(Id) DESC, MAX(CreatedDate) DESC';
        
        try {
            for (AggregateResult ar : Database.query(query)) {
                results.add(new MatterDetail(
                    (String) ar.get('matterId'),
                    (String) ar.get('matterDisplayName'), // Use Display Name field
                    (String) ar.get('matterStatus'),
                    (String) ar.get('clientName'),
                    (Integer) ar.get('unresolvedCount'),
                    (DateTime) ar.get('lastMessageDate')
                ));
            }
        } catch (Exception e) {
            System.debug('Error in getStageMatters: ' + e.getMessage());
        }
        
        return results;
    }
    
    public class TeamUnresolvedCount {
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Integer count { get; set; }
        
        public TeamUnresolvedCount(String name, Integer count) {
            this.name = name;
            this.count = count;
        }
    }
    
    public class StageBreakdown {
        @AuraEnabled public String stageName { get; set; }
        @AuraEnabled public Integer count { get; set; }
        
        public StageBreakdown(String stageName, Integer count) {
            this.stageName = stageName;
            this.count = count;
        }
    }
    
    public class MatterDetail {
        @AuraEnabled public String matterId { get; set; }
        @AuraEnabled public String matterName { get; set; }
        @AuraEnabled public String matterStatus { get; set; }
        @AuraEnabled public String clientName { get; set; }
        @AuraEnabled public Integer unresolvedCount { get; set; }
        @AuraEnabled public DateTime lastMessageDate { get; set; }
        
        public MatterDetail(String matterId, String matterName, String matterStatus, 
                           String clientName, Integer unresolvedCount, DateTime lastMessageDate) {
            this.matterId = matterId;
            this.matterName = matterName;
            this.matterStatus = matterStatus;
            this.clientName = clientName;
            this.unresolvedCount = unresolvedCount;
            this.lastMessageDate = lastMessageDate;
        }
    }
}
