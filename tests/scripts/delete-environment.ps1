$Environment = "net-core-test-20210226.1"
$TeamProject = "ronaldbosma"
$OrganizationUrl = "https://dev.azure.com/ronaldbosma"

$environmentName = $Environment.Replace(".", "-");

$environmentId = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject `
    --org $OrganizationUrl `
    --api-version "6.0-preview" `
    --query "value[?name=='$environmentName'].id" `
    --output tsv

Write-Host "Delete environment $environmentName with id $environmentId"
az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject environmentId=$environmentId `
    --org $OrganizationUrl `
    --http-method DELETE `
    --api-version "6.0-preview"