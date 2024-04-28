data "azurerm_resource_group" "conference-rg" {
  name     = "esrmnt-oidc-poc-rg"
}

data "azurerm_api_management" "apim" {
  name                = "esrmnt-oidc-poc-apim"
  resource_group_name = data.azurerm_resource_group.conference-rg.name
}

resource "azurerm_api_management_api" "conference" {
  name                = "conference-api-v2"
  resource_group_name = data.azurerm_resource_group.conference-rg.name
  api_management_name = data.azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Conference API"
  path                = "conference"
  protocols           = ["https"]

  import {
    content_format = "swagger-link-json"
    content_value  = "http://conferenceapi.azurewebsites.net/?format=json"
  }

  oauth2_authorization {
    authorization_server_name = azurerm_api_management_authorization_server.apim-authorization-server.name
  }
}

resource "azurerm_api_management_api_operation" "conference-operation" {
  operation_id        = "user-delete"
  api_name            = azurerm_api_management_api.conference.name
  api_management_name = azurerm_api_management_api.conference.api_management_name
  resource_group_name = data.azurerm_resource_group.conference-rg.name
  display_name        = "Delete User Operation"
  method              = "DELETE"
  url_template        = "/users/{id}/delete"
  description         = "This can only be done by the logged in user."

  template_parameter {
    name     = "id"
    type     = "number"
    required = true
    description = "id of the user to be deleted"
    default_value = "user_id_00"
    values = ["user_id_00","user_id_00", "user_id_02"]
  }

  response {
    status_code = 200
  }
}


resource "azurerm_api_management_product" "conference-product" {
  product_id            = "conference-product-oidc"
  api_management_name   = azurerm_api_management_api.conference.api_management_name
  resource_group_name   = data.azurerm_resource_group.conference-rg.name
  display_name          = "Conference Product"
  description           = "Conference Product"
  subscription_required = true
  subscriptions_limit   = 1
  approval_required     = true
  published             = true
}

resource "azurerm_api_management_product_api" "conference-product-api" {
  api_name            = azurerm_api_management_api.conference.name
  product_id          = azurerm_api_management_product.conference-product.product_id
  api_management_name = azurerm_api_management_api.conference.api_management_name
  resource_group_name = data.azurerm_resource_group.conference-rg.name
}


resource "azurerm_api_management_authorization_server" "apim-authorization-server" {
  name                         = "authorization_server"
  api_management_name          = data.azurerm_api_management.apim.name
  resource_group_name          = data.azurerm_resource_group.conference-rg.name
  display_name                 = "Authorization Server Log API"
  authorization_endpoint       = "https://login.microsoftonline.com/***********************/oauth2/v2.0/authorize"
  token_endpoint               = "https://login.microsoftonline.com/***********************/oauth2/v2.0/token"
  client_id                    = "60bb***********************115f"
  client_registration_endpoint = "https://esrmnt-oidc-poc-apim.developer.azure-api.net"
  bearer_token_sending_methods = ["authorizationHeader"]

  grant_types = [
    "authorizationCode",
  ]
  authorization_methods = [
    "GET", "POST"
  ]

  default_scope = "api://60bb**********************115f/Log.Read"
  client_authentication_method = ["Body"]
}