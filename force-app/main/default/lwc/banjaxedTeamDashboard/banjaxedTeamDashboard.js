import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getTeamUnresolvedCounts from '@salesforce/apex/BanjaxedReportController.getTeamUnresolvedCounts';
import getTeamStageBreakdown from '@salesforce/apex/BanjaxedReportController.getTeamStageBreakdown';
import getStageMatters from '@salesforce/apex/BanjaxedReportController.getStageMatters';

export default class BanjaxedTeamDashboard extends NavigationMixin(LightningElement) {
    @track showOverview = true;
    @track showTeamDetail = false;
    @track showMattersDetail = false;
    @track selectedTeamName = '';
    @track selectedStageName = '';
    @track selectedTeamTotal = 0;
    @track selectedTeamStages = [];
    @track selectedStageMatters = [];
    
    @track criticalTeams = [];      // >200 unresolved
    @track highPriorityTeams = [];  // 100-200 unresolved
    @track moderateTeams = [];      // 25-99 unresolved
    @track goodTeams = [];          // <25 unresolved
    @track allTeams = [];

    @wire(getTeamUnresolvedCounts)
    wiredTeamData({ error, data }) {
        if (data) {
            this.processTeamData(data);
        } else if (error) {
            console.error('Error loading team data:', error);
        }
    }

    processTeamData(teams) {
        this.allTeams = teams;
        
        // Updated color thresholds: Green <25, Red >200
        this.criticalTeams = teams.filter(team => team.count > 200);
        this.highPriorityTeams = teams.filter(team => team.count >= 100 && team.count <= 200);
        this.moderateTeams = teams.filter(team => team.count >= 25 && team.count < 100);
        this.goodTeams = teams.filter(team => team.count < 25);
    }

    // Computed properties for conditional rendering
    get hasCriticalTeams() {
        return this.criticalTeams && this.criticalTeams.length > 0;
    }

    get hasHighPriorityTeams() {
        return this.highPriorityTeams && this.highPriorityTeams.length > 0;
    }

    get hasModerateTeams() {
        return this.moderateTeams && this.moderateTeams.length > 0;
    }

    get hasGoodTeams() {
        return this.goodTeams && this.goodTeams.length > 0;
    }

    handleTeamClick(event) {
        const teamName = event.currentTarget.dataset.team;
        this.selectedTeamName = teamName;
        
        // Find team total
        const team = this.allTeams.find(t => t.name === teamName);
        this.selectedTeamTotal = team ? team.count : 0;
        
        // Load stage breakdown
        this.loadTeamStageBreakdown(teamName);
        
        // Switch to detail view
        this.showOverview = false;
        this.showTeamDetail = true;
    }

    loadTeamStageBreakdown(teamName) {
        getTeamStageBreakdown({ teamName: teamName })
            .then(result => {
                this.selectedTeamStages = result.map(stage => ({
                    name: stage.stageName,
                    count: stage.count,
                    percentage: Math.round((stage.count / this.selectedTeamTotal) * 100),
                    icon: this.getStageIcon(stage.stageName),
                    barStyle: `width: ${Math.round((stage.count / this.selectedTeamTotal) * 100)}%`
                }));
            })
            .catch(error => {
                console.error('Error loading stage breakdown:', error);
            });
    }

    getStageIcon(stageName) {
        const iconMap = {
            'Treatment': '🚨',
            'Verification': '📊',
            'Negotiation': '🤝',
            'Settlement': '💰',
            'Money Received': '✅',
            'Litigation': '⚖️',
            'Closed': '📁',
            'DSB Ready': '📋',
            'Closed - Rejected': '❌'
        };
        return iconMap[stageName] || '📊';
    }

    handleStageClick(event) {
        const stageName = event.currentTarget.dataset.stage;
        this.selectedStageName = stageName;
        
        // Load matters for this team and stage
        this.loadStageMatters(this.selectedTeamName, stageName);
        
        // Switch to matters detail view
        this.showTeamDetail = false;
        this.showMattersDetail = true;
    }

    loadStageMatters(teamName, stageName) {
        getStageMatters({ teamName: teamName, stageName: stageName })
            .then(result => {
                this.selectedStageMatters = result.map(matter => ({
                    id: matter.matterId,
                    name: matter.matterName,
                    status: matter.matterStatus,
                    clientName: matter.clientName,
                    unresolvedCount: matter.unresolvedCount,
                    lastMessageDate: this.formatDate(matter.lastMessageDate)
                }));
            })
            .catch(error => {
                console.error('Error loading stage matters:', error);
            });
    }

    formatDate(dateString) {
        if (!dateString) return 'N/A';
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    }

    handleBackToStagesClick() {
        this.showMattersDetail = false;
        this.showTeamDetail = true;
        this.selectedStageName = '';
        this.selectedStageMatters = [];
    }

    handleViewMatter(event) {
        const matterId = event.currentTarget.dataset.matterId;
        // Navigate to matter record page
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: matterId,
                actionName: 'view'
            }
        });
    }

    handleBackClick() {
        this.showOverview = true;
        this.showTeamDetail = false;
        this.showMattersDetail = false;
        this.selectedTeamName = '';
        this.selectedStageName = '';
        this.selectedTeamStages = [];
        this.selectedStageMatters = [];
    }
}