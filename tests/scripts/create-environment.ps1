$Environment = "net-core-test-20210226.1"
$TeamProject = "ronaldbosma"
$OrganizationUrl = "https://dev.azure.com/ronaldbosma"

$environmentName = $Environment.Replace(".", "-");

$createEnvironmentBody = @{ name = $environmentName; description = "Provisioned environment $environmentName" };
$createEnvironmentFile = "create-environment-body.json";
Set-Content -Path $createEnvironmentFile -Value ($createEnvironmentBody | ConvertTo-Json);

Write-Host "Create environment $environmentName in team project $TeamProject"
$environment = az devops invoke `
    --area distributedtask `
    --resource environments `
    --route-parameters project=$TeamProject `
    --org $OrganizationUrl `
    --http-method POST `
    --in-file $createEnvironmentFile `
    --api-version "6.0-preview";

Remove-Item $createEnvironmentFile -Force;