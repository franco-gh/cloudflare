# iamfranco.com DNS Configuration
# Update these values according to your DNS requirements

domain_name = "iamfranco.com"
zone_plan   = "free"

# DNS Records Configuration
dns_records = {
  # Root domain (A record)
  "root" = {
    type    = "A"
    name    = "@"
    content = "192.168.1.100"  # Replace with your server IP
    ttl     = 1               # Auto TTL
    proxied = false
    comment = "Root domain A record"
  }

  # WWW subdomain (CNAME to root)
  "www" = {
    type    = "CNAME"
    name    = "www"
    content = "iamfranco.com"
    ttl     = 1
    proxied = false
    comment = "WWW subdomain"
  }

  # Mail server (MX record)
  "mail_mx" = {
    type     = "MX"
    name     = "@"
    content  = "mail.iamfranco.com"
    ttl      = 1
    priority = 10
    proxied  = false
    comment  = "Primary mail server"
  }

  # Mail server A record
  "mail_a" = {
    type    = "A"
    name    = "mail"
    content = "192.168.1.101"  # Replace with your mail server IP
    ttl     = 1
    proxied = false
    comment = "Mail server A record"
  }

  # SPF record for email
  "spf" = {
    type    = "TXT"
    name    = "@"
    content = "v=spf1 mx a:mail.iamfranco.com -all"
    ttl     = 1
    proxied = false
    comment = "SPF record for email authentication"
  }

  # DKIM record (example - replace with your actual DKIM)
  "dkim" = {
    type    = "TXT"
    name    = "default._domainkey"
    content = "v=DKIM1; k=rsa; p=your_dkim_public_key_here"
    ttl     = 1
    proxied = false
    comment = "DKIM record for email authentication"
  }

  # DMARC record
  "dmarc" = {
    type    = "TXT"
    name    = "_dmarc"
    content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@iamfranco.com"
    ttl     = 1
    proxied = false
    comment = "DMARC policy record"
  }

  # Example subdomain
  "api" = {
    type    = "A"
    name    = "api"
    content = "192.168.1.102"  # Replace with your API server IP
    ttl     = 1
    proxied = false
    comment = "API subdomain"
  }
}

# Zone settings
ssl_mode                 = "full"
always_use_https        = true
min_tls_version         = "1.2"
automatic_https_rewrites = true

security_level = "medium"
challenge_ttl  = 1800
browser_check  = "on"

brotli      = "on"
minify_css  = true
minify_html = true
minify_js   = true

development_mode = false
enable_dnssec    = true