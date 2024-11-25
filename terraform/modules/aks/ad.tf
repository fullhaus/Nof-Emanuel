resource "azuread_group" "aks_admins" {
  display_name     = "${var.project}-${var.environment}-AKS-Admins"
  security_enabled = true
  mail_enabled     = false
  description      = "Azure AD group for AKS administrators ${var.project}-${var.environment}"
}

resource "azuread_group_member" "aks_admins_users" {
  for_each = toset(var.ad_group_member)

  group_object_id  = azuread_group.aks_admins.id
  member_object_id = each.value
}
