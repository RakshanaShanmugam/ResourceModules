function DiscoverResources {

    [CmdletBinding()]
    param (
        [PSCustomObject]
        $SubscriptionObject,

        [string]
        $statePath = $pwd
    )

    $settingfile = Get-Content -Path "$statePath/utilities/tools/Carmlizer/src/Settings.json"
    $resourceGroups = Get-AzResourceGroup
    $resourceGroupApiVersion = ((Get-AzResourceProvider -ProviderNamespace Microsoft.Resources).ResourceTypes | Where-Object ResourceTypeName -EQ resourceGroups).ApiVersions[0]
    $SkipResourceGroupFlag = ($settingfile | ConvertFrom-Json).RelocationSettings.SkipResourceGroup
    $WorkloadNameFlag = ($settingfile | ConvertFrom-Json).RelocationSettings.WorkloadName
    $RelocationSettings = ($settingfile | ConvertFrom-Json).RelocationSettings.SkipResourceType

    foreach ($resourceGroup in $resourceGroups) {
        ## Skipping Resource groups mentioned in settings.json
        if ($resourceGroup.ResourceGroupName -notin $SkipResourceGroupFlag) {
            ## skipping resource types mentioned in settings.json
            $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName | Where-Object { $_.Type -notin $RelocationSettings }

            $resourceGroupPath = (Join-Path -Path "$statePath/$WorkloadNameFlag/$($subscriptionObject.Name)/" -ChildPath "$($resourceGroup.ResourceGroupName)")
            $tmplocation = (Join-Path -Path "$statePath" -ChildPath '/local')
            ## Creating workload named folder in current working directory if it doesn't exist
            if (!(Test-Path -Path $resourceGroupPath)) {
                New-Item -Path $resourceGroupPath -ItemType Directory
            }
            $resourceGroupArm = Get-AzResourceGroup -Name $resourceGroup.ResourceGroupName | Select-Object ResourceGroupName, Location, Tags
            $jqJsonTemplate = Join-Path -Path $statePath -ChildPath 'utilities/tools/Carmlizer/src/data/resourceGroups.template.jq'
            ## Using jq since export-template doesn't work for Resource Groups
            $resourceGroupArm | Add-Member -Name 'ApiVersion' -MemberType NoteProperty -Value $resourceGroupApiVersion
            $object = ($resourceGroupArm | ConvertTo-Json -Depth 100 -EnumsAsStrings | jq -r -f $jqJsonTemplate | ConvertFrom-Json)
            ConvertTo-Json -InputObject $object -Depth 100 -EnumsAsStrings | Set-Content -Path "$tmplocation/$($resourceGroup.ResourceGroupName).deploy.json" -Encoding UTF8 -Force
            $resourceGroupTemplateFolderPath = Join-Path -Path $resourceGroupPath -ChildPath '/Microsoft.Resources_resourceGroups'
            ## Making neccessary directories
            if (!(Test-Path -Path $resourceGroupTemplateFolderPath) ) {
                New-Item -Path $resourceGroupTemplateFolderPath -ItemType Directory
            }

            $resourceGroupTemplatePath = Join-Path -Path $resourceGroupTemplateFolderPath -ChildPath "$($resourceGroup.ResourceGroupName).deploy.json"
            ## Exporting template to the processed location
            #Curated-ExportedARM -exportedArmLocation "$tmplocation/$($resourceGroup.ResourceGroupName).deploy.json" -proccessedArmLocation $resourceGroupTemplatePath
            ## Exporting ARM parameters to the processed location from temp
            #Generate-ARMParameters -exportedArmLocation $resourceGroupTemplatePath -proccessedArmLocation $resourceGroupParameterTypePath

            foreach ($resource in $resources) {
                $resourceType = $resource.ResourceType
                $resourceType = $resourceType.Replace('/', '_')
                $resourcePath = (Join-Path -Path $resourceGroupPath -ChildPath "/$($resourceType)")
                if (!(Test-Path -Path $resourcePath)) {
                    New-Item -Path $resourcePath -ItemType Directory
                }

                $rName = $($resource.Name).Replace('/', '_')
                $tempExportPath = Join-Path -Path $resourcePath -ChildPath "/$rName.deploy.json"
                $paramExportPath = Join-Path -Path $resourcePath -ChildPath "/$rName.parameters.json"
                ## Exporting ARM Template for resources
                Export-AzResourceGroup -Resource $resource.ResourceId -ResourceGroupName $resourceGroup.ResourceGroupName -Path $tempExportPath -SkipAllParameterization -Confirm:$false -Force
                #Curated-ExportedARM -exportedArmLocation "$tmplocation/$($resourceGroup.ResourceGroupName)/$rName.json" -proccessedArmLocation $tempExportPath

                ## Generating Parameter files for resources
                Convert-ARMToBicepParameters -exportedArmLocation $tempExportPath -proccessedArmLocation $paramExportPath
                Write-Host 'Enhjd'
            }

        }

    }
}
