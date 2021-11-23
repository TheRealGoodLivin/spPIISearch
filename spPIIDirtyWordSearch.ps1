###############################################################
#### CREATED FOR DIRTY WORDS SEARCHES IN SHAREPOINT ONLINE ####
###############################################################
################# CREATED BY Austin Livengood #################
###############################################################

# CHANGABLE VARIABLES
$sitePath = "https://usaf.dps.mil/sites/52msg/CS/SCX/IAO/" # SITE PATH
$reportPath = "C:\users\$env:USERNAME\Desktop\$((Get-Date).ToString("yyyyMMdd_HHmmss"))_SitePIIResults.csv" # REPORT PATH (DEFAULT IS TO DESK
$results = @() # RESULTS
$dirtyWords = @("*CUI*","*(CUI)*","*UPMR*","*SURF*","*(PA)*","*2583*","*SF86*","*SF 86*","*FOUO*","*GTC*","*medical*","*AF469*","*AF 469*","*469*","*Visitor Request*","*VisitorRequest*","*Visitor*","*eQIP*","*EPR*","*910*","*AF910*","*AF 910*","*911*","*AF911*","*AF 911*","*OPR*","*eval*","*feedback*","*loc*","*loa*","*lor*","*alpha roster*","*alpha*","*roster*","*recall*","*SSN*","*SSAN*","*AF1466*","*1466*","*AF 1466*","*AF1566*","*AF 1566*","*1566*","*SGLV*","*SF182*","*182*","*SF 182*","*allocation notice*","*credit*","*allocation*","*2583*","*AF 1466*","*AF1466*","*1466*","*AF1566*","*AF 1566*","*1566*","*AF469*","*AF 469*","*469*","*AF 422*","*AF422*","*422*","*AF910*","*AF 910*","*910*","*AF911*","*AF 911*","*911*","*AF77*","*AF 77*","*77*","*AF475*","*AF 475*","*475*","*AF707*","*AF 707*","*707*","*AF709*","*AF 709*","*709*","*AF 724*","*AF724*","*724*","*AF912*","*AF 912*","*912*","*AF 931*","*AF931*","*931*","*AF932*","*AF 932*","*932*","*AF948*","*AF 948*","*948*","*AF 3538*","*AF3538*","*3538*","*AF3538E*","*AF 3538E*","*AF2096*","*AF 2096*","*2096*","*AF 2098*","*AF2098*","*AF 2098*","*AF 3538*","*AF3538*","*3538*","*1466*","*1566*","*469*","*422*","*travel*","*SF128*","*SF 128*","*128*","*SF 86*","*SF86*","*86*","*SGLV*","*SGLI*","*DD214*","*DD 214*","*214*","*DD 149*","*DD149*","*149*")

Connect-PnPOnline -Url $sitePath -UseWebLogin # CONNECT TO SPO
$subSites = Get-PnPSubWeb -Recurse # GET ALL SUBSITES
$getDocLibs = Get-PnPList | Where-Object {$_.BaseTemplate -eq 101}

# GET PARENT DOCUMENT LIBRARIES
foreach ($DocLib in $getDocLibs) {
    $allItems = Get-PnPListItem -List $DocLib -Fields "FileRef", "File_x0020_Type", "FileLeafRef", "File_x0020_Size"
   
    #LOOP THROUGH EACH DOCMENT IN THE PARENT SITES
    foreach ($Item in $allItems) {
        foreach ($word in $dirtyWords) {
            if (($Item["FileLeafRef"] -like $word)) {
                Write-Host "File found. Under:" $word "Path:" $Item["FileRef"] -ForegroundColor Red

                $permissions = @()
                $perm = Get-PnPProperty -ClientObject $Item -Property RoleAssignments       
                foreach ($role in $Item.RoleAssignments) {
                    $loginName = Get-PnPProperty -ClientObject $role.Member -Property LoginName
                    $rolebindings = Get-PnPProperty -ClientObject $role -Property RoleDefinitionBindings
                    $permissions += "$($loginName) - $($rolebindings.Name)"
                    write-host "$($loginName) - $($rolebindings.Name)" -ForegroundColor Yellow
                }
                $permissions = $permissions | Out-String
           
                $results += New-Object PSObject -Property @{
                    FileName = $subItem["FileLeafRef"]
                    FileExtension = $subItem["File_x0020_Type"]
                    FileSize = $subItem["File_x0020_Size"]
                    Path = $subItem["FileRef"]
                    Permissions = $permissions
                    Criteria = $word
                }
            }
        }
    }
}

# GET ALL SUB SITE DOCUMENT LIBRARIES
foreach ($site in $subSites) {
    Connect-PnPOnline -Url $site.Url -UseWebLogin # CONNECT TO SPO SUBSITE
    $getSubDocLibs = Get-PnPList | Where-Object {$_.BaseTemplate -eq 101}

    foreach ($subDocLib in $getSubDocLibs) {
        $allSubItems = Get-PnPListItem -List $subDocLib -Fields "FileRef", "File_x0020_Type", "FileLeafRef", "File_x0020_Size"
   
        #LOOP THROUGH EACH DOCMENT IN THE SUB SITES
        foreach ($subItem in $allSubItems) {
            foreach ($word in $dirtyWords) {
                if (($subItem["FileLeafRef"] -like $word)) {
                    Write-Host "File found. Under:" $word "Path:" $subItem["FileRef"] -ForegroundColor Red

                    $permissions = @()
                    $perm = Get-PnPProperty -ClientObject $subItem -Property RoleAssignments       
                    foreach ($role in $subItem.RoleAssignments) {
                        $loginName = Get-PnPProperty -ClientObject $role.Member -Property LoginName
                        $rolebindings = Get-PnPProperty -ClientObject $role -Property RoleDefinitionBindings
                        $permissions += "$($loginName) - $($rolebindings.Name)"
                        write-host "$($loginName) - $($rolebindings.Name)" -ForegroundColor Yellow
                    }
                    $permissions = $permissions | Out-String
           
                    $results += New-Object PSObject -Property @{
                        FileName = $subItem["FileLeafRef"]
                        FileExtension = $subItem["File_x0020_Type"]
                        FileSize = $subItem["File_x0020_Size"]
                        Path = $subItem["FileRef"]
                        Permissions = $permissions
                        Criteria = $word
                    }
                }
            }
        }
    }
}
$results | Select-Object "FileName", "FileExtension", "FileSize", "Path", "Permissions", "Criteria" | Export-Csv -Path $reportPath -NoTypeInformation
