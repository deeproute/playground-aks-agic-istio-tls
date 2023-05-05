
# We need to specify that the frontend certificate is a CA so that curl doesn't give an error while validating the certificate CA:
# https://unix.stackexchange.com/a/582310

# There isn't a way to specify that a certificate is a CA when using the azurerm_key_vault_certificate resource:
# https://github.com/Azure/azure-rest-api-specs/issues/11962#issuecomment-827181465
# So we have to manually create it using the tls provider of Terraform.. which is way more tricky to do. Check line 22.
# Also, Key Vault only supports:
# - PFX for SSL Certificates 
# - CER for trusted root certificates
# and terraform only supports PEM. So we need to convert PEM to PFX/CER.


resource "tls_private_key" "frontend" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "frontend" {
  private_key_pem = tls_private_key.frontend.private_key_pem

  is_ca_certificate = true

  subject {
    common_name = "frontend.example.com"
  }

  validity_period_hours = 8760 # 365 days

  allowed_uses = [
    "crl_signing",
    "data_encipherment",
    "digital_signature",
    "key_agreement",
    "cert_signing",
    "key_encipherment",
    "server_auth",
    "client_auth"
  ]
}

resource "local_sensitive_file" "frontend_key" {
  content  = tls_private_key.frontend.private_key_pem
  filename = "../certs/frontend.example.com.key"
}

resource "local_file" "frontend_cert" {
  content  = tls_self_signed_cert.frontend.cert_pem
  filename = "../certs/frontend.example.com.crt"
}

# Azure App GW requires the root certificate to be of CER format
# Azure App GW requires the SSL certificates to be of PFX format
# Here's a workaround to generate a root certificate in PFX Format:
# https://github.com/hashicorp/terraform-provider-tls/issues/36#issuecomment-766193746
# 
# How to generate a CER format Certificate:
# https://unix.stackexchange.com/a/131338/407175

# Generate PFX certificate for SSL Certificate
resource "null_resource" "pem2pfx" {
  triggers = {
    filebase64_cert = local_file.frontend_cert.content_base64          # this should only trigger when the file contents changes
    filebase64_key  = local_sensitive_file.frontend_key.content_base64 # this should only trigger when the file contents changes
    command         = "openssl pkcs12 -inkey ${local_sensitive_file.frontend_key.filename} -in ${local_file.frontend_cert.filename} -passout pass:password -export -out ../certs/frontend.example.com.pfx"
  }

  provisioner "local-exec" {
    command = self.triggers.command
  }
}

data "local_file" "frontend_pfx" {
  filename = "../certs/frontend.example.com.pfx"

  depends_on = [
    null_resource.pem2pfx
  ]
}

resource "azurerm_key_vault_certificate" "frontend" {
  name         = "frontend-cert"
  key_vault_id = module.akv.key_vault_id

  certificate {
    contents = data.local_file.frontend_pfx.content_base64
    password = "password"
  }
}