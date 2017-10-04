Import-Module RESTAPI/Tableau-REST.PSM1




# Sign in to Default Site
TS-SignIn -server localhost:8080 -username glen -password password

DeleteRevisionHistory

#Get Other Sites on Server

$Sites = TS-QuerySites | Where-Object {$_.state -eq 'Active' -and $_.contentUrl.length -gt 0}

ForEach ($site in $Sites)
 {
  "Site: " + $Site.name

  #Chnage to this site, and delete Revision History
  TS-ChangeToSite -SiteID $site.contentUrl
  DeleteRevisionHistory

  " "
 }

TS-SignOut
 
Function DeleteRevisionHistory()
{
 $DataSources = TS-QueryDataSources

 ForEach ($DS in $DataSources)
  {
   $Revisions = TS-GetDataSourceRevisions -DataSourceName $DS.Name -ProjectName $DS.Project | Where-Object {$_.isDeleted -eq 'false' -and $_.isCurrent -eq 'false'}
   ForEach ($Revs in $Revisions)
    {
        $Revs.DataSourceName
        TS-RemoveDataSourceRevision -DataSourceName   $Revs.DataSourceName -ProjectName $Revs.Project -RevisionNumber $Revs.RevisionNumber
    }
  }
}
