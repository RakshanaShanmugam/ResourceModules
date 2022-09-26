function SecretHandling {
    Param(
        [parameter(mandatory)][string] $KeyvaultID,
        [parameter(mandatory)][string] $Rtype,
        [parameter(mandatory= $false)][array] $SecretName,
        [parameter(mandatory= $false)][string] $CertificateName,
        [parameter(mandatory= $false)][string] $keyName

        )
        if(($Rtype -eq "Microsoft.Compute/virtualMachines") -or ($Rtype -eq "Microsoft.Compute/virtualMachineScaleSets") -or ($Rtype -eq "Microsoft.DBforPostgreSQL/flexibleServers") -or ($Rtype -eq "Microsoft.Sql/servers"))
        {
            $json = @"
"adminPassword": {
"reference": {
"keyVault": {
"id": $keyvaultID
},
"secretName": $($SecretName[0]) }
}
"@
$json     
        }
        if($Rtype -eq "Microsoft.DataFactory/factories")
        {
        $json=@"
        "cMKKeyName": {
            "value": $($secretName[0])
        },
        "cMKKeyVaultResourceId": {
            "value": $keyVaultID
        }
"@
$json
        }
        if(($Rtype -eq "Microsoft.MachineLearningServices/workspaces") -or ($Rtype -eq "Microsoft.ServiceBus/namespaces") -or ($Rtype -eq "Microsoft.Synapse/workspaces/.test/encryptionwsai"))
        {
        $json=@"
        "associatedKeyVaultResourceId": {
            "value": $keyVaultID
        }
"@
$json
        }
        if ($Rtype -eq "Microsoft.AAD/DomainServices")
        {
           $json=@"
           "pfxCertificate": {
            "reference": {
                "keyVault": {
                    "id": $keyVaultID
                },
                "secretName": $($secretName[0])
            }
        },
        "pfxCertificatePassword": {
            "reference": {
                "keyVault": {
                    "id": $keyVaultID
                },
                "secretName": $($secretName[1])
            }
        }
"@
$json
        }
        if ($Rtype -eq "Microsoft.ApiManagement/service")
        {
        $json=@"
        "authorizationServers": {
            "value": [
                {
                    "name": "AuthServer1",
                    "authorizationEndpoint": "https://login.microsoftonline.com/651b43ce-ccb8-4301-b551-b04dd872d401/oauth2/v2.0/authorize",
                    "grantTypes": [
                        "authorizationCode"
                    ],
                    "clientCredentialsKeyVaultId": $keyVaultID
                    "clientIdSecretName": $($secretName[0])
                    "clientSecretSecretName": $($secretName[1])
                    "clientRegistrationEndpoint": "http://localhost",
                    "tokenEndpoint": "https://login.microsoftonline.com/651b43ce-ccb8-4301-b551-b04dd872d401/oauth2/v2.0/token"
                }
            ]
        }
"@
$json
        }
        if($Rtype -eq "Microsoft.Network/applicationGateways")
        {
        $json=@"
        "sslCertificates": {
            "value": [
                {
                    "name": $($secretName[0]),
                    "properties": {
                        "keyVaultSecretId": "https://$keyVaultID/secrets/$secretName"
                    }
                }
            ]
        }
"@
$json
        }
        if($Rtype -eq "Microsoft.Compute/diskEncryptionSets")
        {
        $json=@"
        "keyVaultResourceId": {
            "value": $keyVaultID
        },
        "keyName": {
            "value": $keyName
"@
$json
        }

    }
##call in main script
##SecretHandling -KeyvaultID $KeyvaultID -Rtype $Rtype -SecretName $SecretName
