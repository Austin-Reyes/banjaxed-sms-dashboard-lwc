# Banjaxed SMS Team Performance Dashboard

An interactive Lightning Web Component dashboard for tracking unresolved SMS messages by team and matter stage in Salesforce.

## Overview

This dashboard provides managers with actionable insights into SMS message performance across different matter teams and stages. It features:

- **Color-coded team performance** with updated thresholds:
  - **Good**: <25 unresolved messages
  - **Moderate**: 25-99 unresolved messages  
  - **High Priority**: 100-200 unresolved messages
  - **Critical**: >200 unresolved messages

- **Two-level drill-down navigation**:
  - Level 1: Organization overview with all teams
  - Level 2: Team-specific stage breakdown with percentages

- **Real-time data** from the last 30 days
- **Responsive design** for desktop and mobile

## Components

### Lightning Web Component
- **banjaxedTeamDashboard**: Main interactive dashboard component
- **Files**: HTML template, JavaScript controller, CSS styling, metadata

### Apex Controller
- **BanjaxedReportController**: Backend data processing
- **Methods**:
  - `getTeamUnresolvedCounts()`: Aggregates unresolved messages by team
  - `getTeamStageBreakdown(teamName)`: Provides stage-level breakdown for specific team

### Custom Tab
- **SMS_Team_Dashboard**: Custom tab configuration for easy access

## Data Sources

The dashboard queries the following Salesforce objects:
- `banjaxed_cm__Banjaxed_Matter_Intake_Message__c` (primary data source)
- `litify_pm__Default_Matter_Team__c` (team assignments)
- `litify_pm__Matter_Stage_Activity__c` (matter stages)

## Deployment Instructions

### Prerequisites
1. Salesforce CLI installed and authenticated to target org
2. Access to production Salesforce org with Banjaxed and Litify packages
3. System Administrator or equivalent permissions

### Step 1: Deploy to Production
```bash
# Navigate to project directory
cd /Users/Austin@reyeslaw.com/CascadeProjects/banjaxed-reporting-lwc/banjaxed-reporting-lwc

# Authenticate to production org (if not already done)
sf org login web --alias production

# Deploy all components
sf project deploy start --target-org production
```

### Step 2: Verify Deployment
1. **Check Apex Class**: Go to Setup → Apex Classes → BanjaxedReportController
2. **Check LWC**: Go to Setup → Lightning Components → banjaxedTeamDashboard
3. **Check Custom Tab**: Go to Setup → Tabs → SMS Team Dashboard

### Step 3: Add Tab to App
1. Go to Setup → App Manager
2. Edit your desired Lightning App
3. Add "SMS Team Dashboard" tab
4. Save and activate

### Step 4: Set Permissions
1. Go to Setup → Permission Sets or Profiles
2. Grant access to:
   - BanjaxedReportController Apex class
   - SMS Team Dashboard tab
   - Required custom objects (banjaxed_cm__*, litify_pm__*)

## Usage

### For Managers
1. Navigate to the "SMS Team Dashboard" tab
2. View color-coded team performance overview
3. Click any team card to drill down into stage-specific details
4. Use the "Back to Overview" button to return to main view

### Key Metrics
- **Team-level**: Total unresolved messages per team
- **Stage-level**: Breakdown by matter stage with percentages
- **Time-based**: Data from last 30 days
- **Status-based**: Filters for 'RECEIVED' status (unresolved)

## Troubleshooting

### Common Issues
1. **No data showing**: Check object permissions and field-level security
2. **Apex errors**: Verify custom object API names match your org
3. **Tab not visible**: Check app assignments and user permissions

### Debug Steps
1. Open browser Developer Tools → Console
2. Look for JavaScript errors or Apex exceptions
3. Check Debug Logs in Setup → Debug Logs

## Customization

### Adjusting Color Thresholds
Edit the `processTeamData()` method in `banjaxedTeamDashboard.js`:
```javascript
// Current thresholds
this.criticalTeams = teams.filter(team => team.count > 200);
this.highPriorityTeams = teams.filter(team => team.count >= 100 && team.count <= 200);
this.moderateTeams = teams.filter(team => team.count >= 25 && team.count < 100);
this.goodTeams = teams.filter(team => team.count < 25);
```

### Adding New Stage Icons
Update the `getStageIcon()` method in the JavaScript controller.

### Modifying Time Range
Change `LAST_N_DAYS:30` in the Apex SOQL queries to desired timeframe.

## Support

For issues or enhancements, contact your Salesforce administrator or development team.
