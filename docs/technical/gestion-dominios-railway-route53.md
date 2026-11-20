# Gestión de Dominios y Despliegue en Railway con Route 53

Este documento detalla la arquitectura, el aprovisionamiento de infraestructura mediante Infrastructure as Code (OpenTofu) en Amazon Route 53, y la integración de despliegue continuo (CI/CD) con Railway para el ecosistema de ABAQ.

---

## 1. Topología de Red y Dominios

Todos los servicios residen bajo el dominio base parametrizado (`abaq.site`), gestionado en **Amazon Route 53**:

| Subdominio | Servicio Railway | Proyecto Railway | Tipo DNS | Propósito |
|---|---|---|---|---|
| `launcher.<domain>` | `launcher` | `launcher` | CNAME + TXT verify | Portal central de acceso unificado |
| `miportal.<domain>` | `miabaq-frontend` | `miabaq` | CNAME + TXT verify | Frontend Angular (MiPortal) |
| `organizador.<domain>` | `organizador` | `organizador` | CNAME + TXT verify | Gestión institucional y expedientes |

> **Nota DNS (RFC 1912):** En Route 53 no se colocan registros CNAME directamente en el apex (`@` o raíz del dominio) cuando conviven registros NS/SOA/MX. Por ello, cada aplicación corre sobre su subdominio específico con su respectivo token `_railway-verify.<subdominio>.<domain>`.

---

## 2. Aprovisionamiento con OpenTofu (`abaq-domainsManagment`)

La infraestructura es completamente agnóstica a valores confidenciales. Todas las variables se encuentran parametrizadas y se activan condicionalmente:

### Variables Parametrizadas (`variables.tf`)
- `organizador_cname_target` / `organizador_txt_verify`
- `miportal_cname_target` / `miportal_txt_verify`
- `launcher_cname_target` / `launcher_txt_verify`

### Creación Condicional (`main.tf`)
Los registros DNS solo se crean si la variable no está vacía:
```hcl
resource "aws_route53_record" "miportal_cname" {
  count   = var.miportal_cname_target != "" ? 1 : 0
  zone_id = local.zone_id
  name    = "miportal.${var.domain_name}"
  type    = "CNAME"
  ttl     = var.ttl
  records = [var.miportal_cname_target]
}

resource "aws_route53_record" "miportal_txt" {
  count   = var.miportal_txt_verify != "" ? 1 : 0
  zone_id = local.zone_id
  name    = "_railway-verify.miportal.${var.domain_name}"
  type    = "TXT"
  ttl     = var.ttl
  records = [var.miportal_txt_verify]
}
```

### Configuración Privada Local (`terraform.tfvars`)
El archivo de variables locales se mantiene en el `.gitignore` y no debe subirse al control de versiones:
```hcl
domain_name = "<domain>"
miportal_cname_target = "<target-railway-cname>"
miportal_txt_verify   = "<token-verificacion-railway>"
...
```

---

## 3. Pipelines de CI/CD (GitHub Actions)

### Migración de Pipelines
- Los antiguos pipelines basados en Firebase Hosting (`.github/workflows/dev.yml`) han sido archivados en `.github/workflows-archived/` para mantener la trazabilidad histórica sin interferir en los nuevos despliegues.
- Los nuevos workflows utilizan `@railway/cli` para desplegar a demanda sobre el entorno `development`.

### Workflow Estándar (`.github/workflows/deploy-railway-dev.yml`)
```yaml
name: Deploy to Railway (Dev)

on:
  push:
    branches:
      - dev

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Railway CLI
        run: npm install -g @railway/cli

      - name: Deploy to Railway Development
        run: railway up --service <NOMBRE_SERVICIO> --environment development
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

---

## 4. Guía de Configuración de Tokens en GitHub

Para autorizar a GitHub Actions a desplegar en Railway sin exponer credenciales:

1. **Generar Token en Railway:**
   - Inicia sesión en Railway.
   - Ve a **Account Settings** (icono de perfil superior derecho) ➔ **Tokens**.
   - Haz clic en **Create Token** (o Project Token si deseas aislar por proyecto).
   - Asigna un nombre claro (ej. `GITHUB_ACTIONS_DEV`) y copia el token generado.

2. **Cargar Secreto en GitHub:**
   - Dirígete a cada repositorio en GitHub (`backend`, `frontend`, etc.).
   - Ve a **Settings** ➔ **Secrets and variables** ➔ **Actions**.
   - Clic en **New repository secret**.
   - Nombre: `RAILWAY_TOKEN`.
   - Valor: *(pega el token copiado)*.

3. **Ejecución Automática:**
   - Cada vez que se haga push o merge a la rama `dev`, GitHub Actions levantará el contenedor de Node.js, autenticará con `RAILWAY_TOKEN` y ejecutará `railway up`, actualizando el entorno `development` sin tiempo de inactividad.
