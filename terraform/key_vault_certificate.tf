resource "azurerm_key_vault_certificate" "certs" {
  for_each = {
    for cert in var.key_vault_certificates :
    cert.name => cert
  }

  name         = each.key
  key_vault_id = module.akv.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 4096
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = each.value.content_type
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1", "1.3.6.1.5.5.7.3.2"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = each.value.subject_alternative_names
      }

      subject            = each.value.subject_cn
      validity_in_months = each.value.validity_in_months
    }
  }

  depends_on = [
    module.akv
  ]
}
