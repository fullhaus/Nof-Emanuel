# TODO
#$ az ad sp create-for-rbac --name "external-test-test-dns-sp" \
#  --role "Contributor" \
#  --scopes /subscriptions/2fa0e512-f70e-430f-9186-1b06543a848e/resourceGroups/Vasyl-Candidate \
#  --query "{client_id: appId, client_secret: password, tenant_id: tenant}" \
#  --output json


data "azuread_application" "test" {
  display_name = "external-test-test-dns-sp"
}

# Create a new client secret for the existing Azure AD Application
resource "azuread_application_password" "external_dns_secret" {
  application_object_id = data.azuread_application.test.object_id
  display_name          = "external-dns-secret"
  end_date_relative     = "8760h" # Valid for 1 year
}

# az role assignment create \
#  --assignee "b8a4491a-373f-4394-a95f-57b63259c9fd" \
#  --role "DNS Zone Contributor" \
#  --scope "/subscriptions/2fa0e512-f70e-430f-9186-1b06543a848e/resourceGroups/Vasyl-Candidate/providers/Microsoft.Network/dnsZones/nof-emanuel.local"
# resource "azurerm_role_assignment" "dns_contributor_test" {
#   scope                = azurerm_dns_zone.dns_zone.id
#   role_definition_name = "DNS Zone Contributor"
#   principal_id         = data.azuread_application.test.application_id
# }

# Output the newly created secret
output "aad_client_secret" {
  value     = nonsensitive(azuread_application_password.external_dns_secret.value)
  sensitive = false
}