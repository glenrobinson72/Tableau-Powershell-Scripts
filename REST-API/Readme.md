Import-Module Tableau-Rest.psm1


Name: TS-Signin
Syntax: TS-Signin  -server [string] -username [string] -password [string] -protocol ['http','https'] -siteID [string] default=""
Description: Used to sign into a Tableau Server.
   -server		Tableau Server Name (required)
   -username	Account to login as (required)
   -password	Password of the account (required)
   -protocol	either http or https (default is http)
   -siteID		SiteID of site to login into (default is Default Site)
Output:	None
Example: TS-Signin -server localhost -username admin -password Passw0rd -protocol http -siteID Marketing


Name: TS-Signout
Syntax:  TS-Signout
Description: Used to sign out of a Tableau Server.
Output:	None
Example: TS-Signout


Name: TS-QueryProjects
Syntax: TS-QueryProjects
Description: Lists all projects within a site that the user account has access to.
Output: Lists Project Names and Details
Example: TS-QueryProjects

Name: TS-DeleteProject
Syntax:  TS-DeleteProject -ProjectName [string]
Description: Used to delete a project in a site.
	-ProjectName	Name of project to be deleted (required)
Output: None
Example: TS-DeleteProject -ProjectName "HR Reports"


Name: TS-CreateProject
Syntax: TS-CreateProject -ProjectName [string] -Description [string] -ContentPermissions ['ManagedByOwner','LockedToProject']
Description: Creates a Project in a site.
	-ProjectName	Name of Project to be created (required)
	-Description	Description for Project
	-ContentPermissions		either ManagedByOwner or LockedToProject (default)
Output: None	
Example:	TS-CreateProject -ProjectName "HR Reports" -Description "Reports for HR Managers" -ContentPermissions LockedToProject


Name: TS-UpdateProject
Syntax: TS-UpdateProject -ProjectName [string] -NewProjectName [string] -Description [string] -ContentPermissions ['ManagedByOwner','LockedToProject']
Description: Updates Project Details for specified project.
	-ProjectName		Name of Project to be updated (required)
	-NewProjectName		New Name of Project
	-Description		New Description of Project
	-ContentPermissions		either ManagedByOwner or LockedToProject
Output: None
Example:	TS-UpdateProject -ProjectName "HR Reports" -NewProjectName "HR Managers Reports"


Name: TS-QuerySites
Syntax:	TS-QuerySites
Description: Used to get details of Sites on the Tableau Server
Output: List of Sites and their Details
Example: TS-QuerySites


Name: TS-QuerySite
Syntax: TS-QuerySite
Description: Used to get details of site user is logged in to.
Output: Lists site details.
Example: TS-QuerySite


Name: TS-UpdateSite
Syntax:	TS-UpdateSite -NewSiteName [string] -NewSiteID [string] -AdminMode ['ContentAndUsers','ContentOnly'] -State ['Active','Disabled'] -UserQuota [int] -StorageQuota [int] -DisableSubscriptions ['true','false'] -RevisionHistoryEnabled ['true','false'] -RevisionLimit [2-10000]
Description: Used to update settings for the site user is logged in to.
	-NewSiteName		New name for site
	-NewSiteID			New Site ID for site
	-AdminMode			Sets whether Site Admins can manage users and content, or just content
	-State				Sets whether the Site is Active or Disabled
	-UserQuota			Sets the maximum number of users on this site (-1 removes any value already set and reverts to license maximum.)
	-StorageQuota		Sets the maximum amount of space for site in MB
	-DisableSubscriptions	Sets whether subscriptions are enabled or disabled.
	-RevisionHistoryEnabled	Sets whether site maintains revision history
	-RevisionLimit		Sets th maximum number of revisions between 2 and 10000
Output: None	
Example: TS-UpdateSite -NewSiteID "Development" -NewSiteID "Development" -UserQuota 5


Name: TS-CreateSite
Syntax:	TS-CreateSite -SiteName [string] -SiteID [string] -AdminMode ['ContentAndUsers','ContentOnly'] -UserQuota [int] -StorageQuota [int] -DisableSubscriptions ['true','false'] 
Description:	Used to create a new site.
	-SiteName		Name of Site (required)
	-SiteID			Site ID for Site (required)
	-AdminMode			Sets whether Site Admins can manage users and content, or just content
	-UserQuota			Sets the maximum number of users on this site (-1 removes any value already set and reverts to license maximum.)
	-StorageQuota		Sets the maximum amount of space for site in MB
	-DisableSubscriptions	Sets whether subscriptions are enabled or disabled.
Output: None
Example: TS-CreateSite -SiteName "Development" -SiteID "Development" -AdminMode ContentAndUsers -DisableSubscriptions true


Name: TS-ChangeToSite
Syntax: TS-ChangeToSite -SiteID [string]
Description: Used to change the Site that the user account is logged in to.
	-SiteID		Site ID of the site you wish to change to. (required)
Output: None
Example:	TS-ChangeToSite -SiteID "Development"


Name: TS-DeleteSite
Syntax:	TS-DeleteSite -AreYouSure ['yes','no']
Description: Used to delete the site that the user is logged into.
	-AreYouSure		Ensures that the user really wants to delete the site (yes required) 
Output: None
Example: TS-DeleteSite -AreYouSure yes


Name: TS-CreateGroup
Syntax: TS-CreateGroup -GroupName [string] -DomainName [string] -SiteRole ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish') -BackgroundTask ('True', 'False')
Description: Used to create a group on the site that user is logged in to.
	-GroupName		Name of the group (required)
	-DomainName 	Name of the Domain group is member of (Active Directory authentication only. Required only when adding AD group.)
	-SiteRole		Site Role for any group members imported into Tableau Server (Active Directory authentication only.) Default is 'Unlicensed' ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')
	-BackgroundTask Specifies whether importing users from AD is done asynchronously ('True', 'False'). Default is true.
Output: None
Example: TS-CreateGroup -GroupName "HR Managers" -DomainName Corp.local -SiteRole Interactor -BackgroundTask true


Name: TS-DeleteGroup
Syntax: TS-DeleteGroup -GroupName [string] -DomainName [string]
Description: Used to remove a group from the site that the user is logged in to.
	-GroupName		Name of group to be deleted (required)
	-DomainName		Name of domain that the group is a member of (AD authentication only). By default  this is set to local, for Tableau Local groups.
Output: None
Example: TS-DeleteGroup -GroupName "HR Managers" -DomainName Corp.local

Name: TS-QueryGroups
Syntax: TS-QueryGroups
Description: Used to list all groups on a site, and details of them
Output:	List of groups, and group details
Example: TS-QueryGroups


Name: TS-UpdateGroup 
Syntax:	TS-UpdateGroup -GroupName [string] -NewGroupName [string] -DomainName [string] -SiteRole ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish') -BackgroundTask ('True', 'False')
Description: Updates details of selected group on site that user is logged into.
	-GroupName		Name of the group (required)
	-NewGroupName	New Name for group
	-DomainName 	Name of the Domain group is member of (Active Directory authentication only. Required only when updating an AD group.)
	-SiteRole		Site Role for any group members imported into Tableau Server (Active Directory authentication only.) Default is 'Unlicensed' ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')
	-BackgroundTask Specifies whether importing users from AD is done asynchronously ('True', 'False'). Default is true.
Output: None
Example: TS-UpdateGroup -GroupName "HR Managers" -NewGroupName "HR Managers (Interactors)"


Name: TS-GetUsersOnSite
Syntax: TS-GetUsersOnSite
Description: Returns a list of users and user details on the site that the user is logged into.
Output: List of users and their details.
Example: TS-GetUsersOnSite


Name: TS-AddUserToGroup
Syntax: TS-AddUserToGroup -GroupName [string] -UserAccount [string]
Description: Adds a user account to a Tableau Local group on the site the user is logged into.
	-GroupName 	Name of group to add user to (required)
	-UserAccount	User Account to be added (required)
Output: None
Example: TS-AddUserToGroup -GroupName "HR Managers" -UserAccount bob


Name: TS-RemoveUserFromGroup
Syntax: TS-RemoveUserFromGroup -GroupName [string] -UserAccount [string]
Description: Removes a user account from a Tableau Local group on the site the user is logged into.
	-GroupName 	Name of group to remove user account from (required)
	-UserAccount	User Account to be removed (required)
Output: None
Example: TS-RemoveUserFromGroup -GroupName "HR Managers" -UserAccount bob


Name: TS-RemoveUserFromSite
Syntax: TS-RemoveUserFromSite -UserAccount [string]
Description: Removes a user account from the site that the user is logged into.
	-UserAccount	User Account to be removed (required)
Output: None
Example: TS-RemoveUserFromSite -UserAccount bob


Name: TS-GetUsersInGroup **** Not Completed ****
Syntax: TS-GetUsersInGroup -GroupName [string]
Description: Lists user account and details for users in selected group.
	-GroupName	Name of group to be checked (required)
	Note: only works on local groups currently. Update required.
Output: Lists user accounts in group, and user details.
Example: TS-GetUsersInGroup -GroupName "HR Managers"


Name: TS-QueryUser
Syntax: TS-QueryUser -UserAccount [string]
Description: Gets details of selected User Account.
	-UserAccount	User account to be queried. (required)
Output: Lists user's details
Example: TS-QueryUser -UserAccount bob


Name: TS-AddUserToSite
Syntax: TS-AddUserToSite -UserAccount -SiteRole ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')
Description: Adds a user account to the site. If user account doesnt exist on the server, it is created.
	-UserAccount	User account to be added (or created) (required)
	-SiteRole		Role of user account on this site. ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish'). Default is 'Unlicensed'
Output: None
Example: TS-AddUserToSite -UserAccount bob -SiteRole Interactor


Name: TS-UpdateUser
Syntax: TS-UpdateUser -UserAccount [string] -FullName [string] -Email [string] -Password [string] -SiteRole ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')
Description: Update Information for specified user
	-UserAccount	User account to be updated (required)
	-FullName		New Full Name for user account.
	-Email			New Email address for user account.
	-Password		New Password for user account (Not applicable for AD Authentication)
	-SiteRole		New Site role for user account ('Interactor', 'Publisher', 'SiteAdministrator', 'Unlicensed','UnlicensedWithPublish', 'Viewer','ViewerWithPublish')
Output:	None	
Example: TS-UpdateUser -UserAccount bob -FullName "Bob Roberts" -Email bob.roberts@company.com


Name: TS-QuerySchedules
Syntax: TS-QuerySchedules
Description: Lists the schedules on the Tableau Server
Output: List of schedules and their details.
Example: TS-QuerySchedules


Name: TS-QueryExtractRefreshTasks  **** Not Completed ****
Syntax: TS-QueryExtractRefreshTasks -ScheduleName [string]
Description: Lists all Tasks for a given schedules
	-ScheduleName 	Name of schedule to be queried (required)
Output:	List of all tasks assigned to a schedule, and details of the tasks.
Example: TS-QueryExtractRefreshTasks -ScheduleName "Saturday Night"


Name: TS-QueryViewsForSite
Syntax: TS-QueryViewsForSite
Description: Lists all views on a site that the user has access to
Output: Lists all views and details of view`
Example: TS-QueryViewsForSite


Name: TS-QueryWorkbooksForUser
Syntax: TS-QueryWorkbooksForUser -UserAccount [string] -IsOwner ['true','false']
Description: Lists all workbooks that the user account has access to. If IsOwner is selected, then lists only workbooks that user account is owner of.
   -UserAccount		User Account to be queried (required)
   -IsOwner 		Only show workbooks which the user account is owner of. Default is False
Output: List of workbooks and workbook details.
Example: TS-QueryWorkbooksForUser -UserAccount bob -IsOwner True


Name: TS-QueryViewsForWorkbook
Syntax: TS-QueryViewsForWorkbook -WorkbookName [string] -ProjectName [string]
Description: Lists all views for the selected Workbook
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
Output:	Lists all views for a workbook and their details.
Example: TS-QueryViewsForWorkbook -WorkbookName Superstore -ProjectName "Tableau Samples"


Name: TS-QueryWorkbook **** Needs completing ****
Syntax: TS-QueryWorkbook -WorkbookName [string] -ProjectName [string]
Description: Shows Workbook details for selected Workbook.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
Output:	Lists a workbook and its details.
Example: TS-QueryWorkbook -WorkbookName Superstore -ProjectName "Tableau Samples"


Name: TS-QueryWorkbookConnections  **** May need additional work ****
Syntax: TS-QueryWorkbookConnections -WorkbookName [string] -ProjectName [string]
Description: Shows Workbook Connection details for selected Workbook.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
Output:	Lists data source connection details for a workbook and their details.
Example: TS-QueryWorkbookConnections -WorkbookName Superstore -ProjectName "Tableau Samples"


Name: TS-UpdateWorkbook
Syntax: TS-UpdateWorkbook -WorkbookName [string] -ProjectName [string] -NewProjectName [string] -NewOwnerAccount [string] -ShowTabs ['true','false']
Description: Used to update information about a Workbook.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Project that the workbook resides in (required)
	-NewProjectName		Project that workbook is to be moved to.
	-NewOwnerAccount	New Owner of the Workbook
	-ShowTabs			Set whether Workbook shows tabs or not ('true','false')
Output: None
Example: TS-UpdateWorkbook -WorkbookName Superstore -ProjectName "Tableau Samples" -NewProjectName "Archive"


Name: TS-DeleteWorkbook
Syntax: TS-DeleteWorkbook -WorkbookName [string] -ProjectName [string]
Description: Deletes a workbook from a site.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
Output: None
Example: TS-DeleteWorkbook -WorkbookName Superstore -ProjectName "Tableau Samples"


Name: TS-AddTagsToWorkbook
Syntax: TS-AddTagsToWorkbook -WorkbookName [string] -ProjectName [string] -Tags [string]
Description: Used to add tags to a workbook
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-Tags				Comma separated list of tags to be added.
Output: None
Example: TS-AddTagstoworkbooks -WorkbookName Superstore -ProjectName "Tableau Samples" -Tags "Superstore,Example"


Name: TS-DeleteTagFromWorkbook
Syntax: TS-AddTagsToWorkbook -WorkbookName [string] -ProjectName [string] -Tag [string]
Description: Used to remove a tag from a workbook
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-Tag				Tag to be removed.
Output: None
Example: TS-DeleteTagFromWorkbook -WorkbookName Superstore -ProjectName "Tableau Samples" -Tag "Superstore"


Name: TS-QueryDataSources  
Syntax: TS-QueryDataSources
Description: Lists all published data sources in a site that the user account has access to.
Output: List of data sources and their details.
Example: TS-QueryDataSources


Name: TS-AddWorkbookToFavorites
Syntax: TS-AddWorkbookToFavorites -WorkbookName [string] -ProjectName [string] -UserAccount [string] -Label [string]
Description: Adds a Workbook to a user account's list of favourites.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-UserAccount		User Account to add favourite to. (required)
	-Label				Label for Workbook in favourites list. (required)
Output: None
Example: TS-AddWorkbookToFavorites -WorkbookName Superstore -ProjectName "Tableau Samples" -UserAccount bob -Label "Superstore Dashboards"


Name: TS-AddViewToFavorites
Syntax: TS-AddViewToFavorites -WorkbookName [string] -ProjectName [string] -ViewName [string] -UserAccount [string] -Label [string]
Description: Adds a View to a user account's list of favourites.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-ViewName			Name of View to be added. (required)
	-UserAccount		User Account to add favourite to. (required)
	-Label				Label for Workbook in favourites list. (required)
Output: None
Example: TS-AddViewToFavorites -WorkbookName Superstore -ProjectName "Tableau Samples"  -ViewName "Order Details" -UserAccount bob -Label "Superstore Order Details"


Name: TS-DeleteWorkbookFromFavorites
Syntax: TS-DeleteWorkbookFromFavorites -WorkbookName [string] -ProjectName [string] -UserAccount [string]
Description: Removes a Workbook from a user account's list of favourites.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-UserAccount		User Account to add favourite to. (required)
Output: None
Example: TS-DeleteWorkbookFromFavorites -WorkbookName Superstore -ProjectName "Tableau Samples" -UserAccount bob


Name: TS-DeleteViewFromFavorites
Syntax: TS-DeleteViewFromFavorites -WorkbookName [string] -ProjectName [string] -ViewName [string] -UserAccount [string] 
Description: Removes a View from a user account's list of favourites.
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-ViewName			Name of View to be added. (required)
	-UserAccount		User Account to add favourite to. (required)
Output: None
Example: TS-DeleteViewFromFavorites -WorkbookName Superstore -ProjectName "Tableau Samples"  -ViewName "Order Details" -UserAccount bob 


Name: TS-QueryProjectPermissions  **** Needs Work to finish ****
Syntax: TS-QueryProjectPermissions -ProjectName [string]
Description: Used to find permissions set for a project
	-ProjectName	Name of project to be queried (required)
Example: TS-QueryProjectPermissions -ProjectName Default


Name: TS-UpdateProjectPermissions
Syntax: TS-UpdateProjectPermissions -ProjectName [string] -GroupName [string] -UserAccount [string] -ViewProject ('Allow','Deny','Blank')..... etc etc
Description: Used to update Project Permissions
	-ProjectName	Name of Project where permissions are being changed (required)
	-GroupName		Name of Group on which permissions will be changed.
	-UserAccount	Name of User account on which permissions will be changed.

	-ViewProject		View Project Permission can be changed to ('Allow', 'Deny', 'Blank')
	-SaveProject		Save Project Permission can be changed to ('Allow', 'Deny', 'Blank')
	-ProjectLeader		Project Leader Permission can be changed to ('Allow', 'Deny', 'Blank')

	-ViewWorkbook		View Workbook Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DownloadImagePDF	Download Image Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DownloadSummaryData	Download Summary Data Permission can be changed to ('Allow', 'Deny', 'Blank')
	-ViewComments		View Comments Permission can be changed to ('Allow', 'Deny', 'Blank')
	-AddComments		Add Comments Permission can be changed to ('Allow', 'Deny', 'Blank')
	-Filter				Filter Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DownloadFullData	Download Full Data Permission can be changed to ('Allow', 'Deny', 'Blank')
	-ShareCustomized	Share Customised Permission can be changed to ('Allow', 'Deny', 'Blank')
	-WebEdit			Web Edit Permission can be changed to ('Allow', 'Deny', 'Blank')
	-SaveWorkbook		Save Workbook Permission can be changed to ('Allow', 'Deny', 'Blank')
	-MoveWorkbook		Move Workbook Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DeleteWorkbook		Delete Workbook Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DownloadWorkbook	Download Workbook Permission can be changed to ('Allow', 'Deny', 'Blank')
	-SetWorkbookPermissions	Set Workbook Permissions can be changed to ('Allow', 'Deny', 'Blank')

	-ViewDataSource		View Data Source Permission can be changed to ('Allow', 'Deny', 'Blank')
	-Connect			Connect to Data Source Permission can be changed to ('Allow', 'Deny', 'Blank')
	-SaveDataSource		Save Data Source Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DownloadDataSource	Download Datasource Permission can be changed to ('Allow', 'Deny', 'Blank')
	-DeleteDataSource	Delete Datasource Permission can be changed to ('Allow', 'Deny', 'Blank')
	-SetDataSourcePermissions	Set Datasource Permissions can be changed to ('Allow', 'Deny', 'Blank')

Output: None
Example: TS-UpdateProjectPermissions -ProjectName "Managers Reports" -GroupName "Managers" -ViewProject Allow -ViewWorkbook Allow -Filter Allow -Connect Allow


Name: TS-PublishDataSource
Syntax: TS-PublishDataSource -ProjectName [string] -DataSourceName [string] -DataSourceFile [string] -DataSourcePath [string] -UserAccount [string] -Password [string] -Embed [string] -OAuth [string] -OverWrite ('true','false')
Description: Used to publish a workbook to Tableau Server.
	-ProjectName	Project that DataSource will reside in (required)
	-DataSourceName	Name of DataSource as it will appear on the Tableau Server (required)
	-DataSourceFile	File name of DataSource to be published (required)
	-DataSourcePath	Path where the DataSource file resides (required)
	-UserAccount	User Account for connection to data source
	-Password		Password for connection to data source
	-Embed		 	Embed user name and password information in workbook
	-OAuth			Use oAuth for connection
	-OverWrite		Overwrite previous versions of the workbook (Default is false)
Output: None	
Example: TS-PublishDataSource -ProjectName Default -DataSourceName "Regional DS" -DataSourceFile "Regional_DS.tds" -DataSourcePath D:\temp -UserAccount connect -Password Passw0rd -Embed true -OverWrite true

Name: TS-QueryDataSource
Syntax: TS-QueryDataSource -ProjectName [string] -DataSourceName [string]
Description: Used to show information about a published datasource.
	-ProjectName 		Location of DataSource (required)	
	-DataSourceName		Name of DataSource (required)	
Output: Information about a published datasource.
Example: TS-QueryDataSource -ProjectName Default -DataSourceName Regional_DS


Name: TS-DeleteDataSource
Syntax: TS-DeleteDataSource -ProjectName [string] -DataSourceName [string]
Description: Used to delete a published datasource.
	-ProjectName 		Location of DataSource (required)	
	-DataSourceName		Name of DataSource (required)	
Output: None
Example: TS-DeleteDataSource -ProjectName Default -DataSourceName Regional_DS


Name: TS-UpdateDataSourceConnection
Syntax: TS-UpdateDataSourceConnection -DataSourceName [string] -ProjectName [string] -ServerName [string] -Port [string] -UserName [string] -Password [string] -embed ('True', 'False')
Description: Used to update a Data Source's connection details
	-DataSourceName		Name of the Data source to be updated (required)		
	-ProjectName		Name of the Project where the Datasource resides. (required)
	-ServerName			Connection Server name to be changed
	-Port				Connection port to be changed.
	-UserName			Connection user name to be changed 
	-Password			Connection password to be changed
	-embed 				Update whether connection details are embedded ('True', 'False')
Output: None
Example: TS-UpdateDataSourceConnection -DataSourceName Regional_DS -ProjectName Default -UserName tabsvc -Password Passw0rd -embed true


Name: TS-PublishWorkbook
Syntax: TS-PublishWorkbook -ProjectName [string] -WorkbookName [string] -WorkbookFile [string] -WorkbookPath [string] -UserAccount [string] -Password [string] -Embed [string] -OAuth [string] -OverWrite ('true','false') -ShowTabs ('true','false')
Description: Used to publish a workbook to Tableau Server.
	-ProjectName	Project that Workbook will reside in (required)
	-WorkbookName	Name of Workbook as it will appear on the Tableau Server (required)
	-WorkbookFile	File name of workbook to be published (required)
	-WorkbookPath	Path where the workbook file resides (required)
	-UserAccount	User Account for connection to data source
	-Password		Password for connection to data source
	-Embed		 	Embed user name and password information in workbook
	-OAuth			Use oAuth for connection
	-OverWrite		Overwrite previous versions of the workbook (Default is false)
	-ShowTabs		Show Views as Tabs (Default is false)
Output: None	
Example: TS-PublishWorkbook -ProjectName Default -WorkbookName "Regional Report" -WorkbookFile "Regionals.twb" -WorkbookPath D:\temp -UserAccount connect -Password Passw0rd -Embed true -OverWrite true -ShowTabs true


Name: TS-DownloadDataSource
Syntax: TS-DownloadDataSource -DatasourceName [string] -ProjectName [string] -FileName [string]
Description: Used to download a Tableau Published Datasource to the selected filename. Downloads can be either .tds or .tdsx depending on the datasource type.
	-DatasourceName		Name of Data Source to be download (required)
	-ProjectName		Name of Project where data source resides. (required)
	-FileName			File name of downloaded file, either .tds or .tdsx (required)
Output:	Downloaded Datasource file.
Example: TS-DownloadDataSource -DatasourceName "Superstore connection" -ProjectName "Tableau Samples" -FileName D:\temp\superstore.tds


Name: TS-DownloadWorkbook
Syntax: TS-DownloadWorkbook -WorkbookName [string] -ProjectName [string] -FileName [string]
Description: Used to download a Tableau Published Datasource to the selected filename. Downloads can be either .tds or .tdsx depending on the datasource type.
	-WorkbookName		Name of Workbook to be download (required)
	-ProjectName		Name of Project where workbook resides. (required)
	-FileName			File name of downloaded file, either .twb or .twbx (required)
Output:	Downloaded Workbook file.
Example: TS-DownloadWorkbook -WorkbookName "Superstore" -ProjectName "Tableau Samples" -FileName D:\temp\superstore.twbx


Name: TS-QueryWorkbookPreviewImage
Syntax: TS-QueryWorkbookPreviewImage -WorkbookName [string] -ProjectName [string] -FileName [string]
Description: Used to download the preview image of a workbook to a file
	-WorkbookName		Name of the workbook (required)
	-ProjectName		Name of Project in which the workbook resides. (required)
	-FileName			File Name of image to be downloaded (PNG format). (required)
Output: Image file is downloaded from server
Example: TS-QueryWorkbookPreviewImage -WorkbookName Superstore -ProjectName "Tableau Samples"  -FileName "D:\temp\Superstore.png"
