
param(
[string[]] $Server,
[string[]] $Username,
[string[]] $Password,
[string[]] $Protocol,
[string[]] $SiteName
)

# Sign in and Create Site
TS-SignIn -server $Server -username $Username -password $Password -protocol $Protocol
TS-CreateSite -SiteName $SiteName -SiteID $SiteName -AdminMode ContentAndUsers
Start-Sleep 2
TS-ChangeToSite -SiteID $SiteName


# Update Default Project Permissions and Create New Projects
TS-UpdateProjectPermissions -ProjectName Default -GroupName "All Users" -ViewProject Blank -SaveProject Blank -ProjectLeader Blank -ViewWorkbook Blank -DownloadImagePDF Blank -DownloadSummaryData Blank -ViewComments Blank -AddComments Blank -Filter Blank -DownloadFullData Blank -ShareCustomized Blank -WebEdit Blank -SaveWorkbook Blank -MoveWorkbook Blank -DeleteWorkbook Blank -DownloadWorkbook Blank -SetWorkbookPermissions Blank -ViewDataSource Blank -Connect Blank -SaveDataSource Blank -DownloadDataSource Blank -DeleteDataSource Blank -SetDataSourcePermissions Blank
TS-CreateProject -ProjectName Sales -ContentPermissions LockedToProject
TS-CreateProject -ProjectName HR -ContentPermissions LockedToProject
TS-CreateProject -ProjectName Marketing -ContentPermissions LockedToProject
TS-CreateProject -ProjectName Managers -ContentPermissions ManagedByOwner
TS-CreateProject -ProjectName KPIs -ContentPermissions ManagedByOwner
TS-CreateProject -ProjectName Directors -ContentPermissions ManagedByOwner


# Create Groups
TS-CreateGroup -GroupName Managers
TS-CreateGroup -GroupName Users
TS-CreateGroup -GroupName Publishers
TS-CreateGroup -GroupName Directors

# Add Users
TS-AddUserToSite -UserAccount Archie
TS-AddUserToSite -UserAccount Barry
TS-AddUserToSite -UserAccount Chas
TS-AddUserToSite -UserAccount Dave
TS-AddUserToSite -UserAccount Edward
TS-AddUserToSite -UserAccount Frank
TS-AddUserToSite -UserAccount Greg
TS-AddUserToSite -UserAccount Harold
TS-AddUserToSite -UserAccount Jonny
TS-AddUserToSite -UserAccount Kenny


# Add Users to Groups
TS-AddUserToGroup -GroupName Managers -UserAccount Archie
TS-AddUserToGroup -GroupName Managers -UserAccount Bill
TS-AddUserToGroup -GroupName Managers -UserAccount Chas
TS-AddUserToGroup -GroupName Directors -UserAccount Dave
TS-AddUserToGroup -GroupName Publishers -UserAccount Archie
TS-AddUserToGroup -GroupName Publishers -UserAccount Harold
TS-AddUserToGroup -GroupName Users -UserAccount Jonny
TS-AddUserToGroup -GroupName Users -UserAccount Kenny
TS-AddUserToGroup -GroupName Users -UserAccount Chas
TS-AddUserToGroup -GroupName Users -UserAccount Bill
TS-AddUserToGroup -GroupName Users -UserAccount Archie


# Update Project Permissions
TS-UpdateProjectPermissions -ProjectName Directors -GroupName Directors -ViewProject Allow -ViewWorkbook Allow -Filter Allow
TS-UpdateProjectPermissions -ProjectName HR -GroupName Managers -ViewProject Allow -ViewWorkbook Allow -Filter Allow -SaveProject Allow -SaveWorkbook Allow -DeleteWorkbook Allow
TS-UpdateProjectPermissions -ProjectName Marketing -GroupName Users -ViewProject Allow -ViewWorkbook Allow -Filter Allow
TS-UpdateProjectPermissions -ProjectName KPIs -GroupName Users -ViewProject Allow -ViewWorkbook Allow -Filter Allow -Connect Allow
TS-UpdateProjectPermissions -ProjectName Directors -GroupName Directors -ViewProject Allow -ViewWorkbook Allow -Filter Allow -Connect Allow
TS-UpdateProjectPermissions -ProjectName Directors -GroupName Publishers -ViewProject Allow -ViewWorkbook Allow -Filter Allow -SaveProject Allow -SaveWorkbook Allow -MoveWorkbook Allow -DeleteDataSource Allow -Connect Allow


# Publish Data Sources
TS-PublishDataSource -Project Directors -DataSourceName DataSource1 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project Directors -DataSourceName DataSource2 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project HR -DataSourceName DataSource3 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project Marketing -DataSourceName DataSource4 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project KPIs -DataSourceName DataSource5 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project KPIs -DataSourceName DataSource6 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp
TS-PublishDataSource -Project HR -DataSourceName DataSource7 -DataSourceFile 'ds1.tdsx' -DataSourcePath C:\temp


# Publish Workbooks
TS-PublishWorkbook -Project HR -WorkbookName 'HR Reporting' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project HR -WorkbookName 'HR Overview' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project Directors -WorkbookName 'Directors KPIs' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project Directors -WorkbookName 'Directors Daily Report' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project KPIs -WorkbookName 'KPI Reporting 1' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project KPIs -WorkbookName 'KPIs 2' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp
TS-PublishWorkbook -Project KPIs -WorkbookName 'KPIs 3' -WorkbookFile 'Test Report.twbx' -WorkbookPath C:\temp


# Sign Out
TS-SignOut



