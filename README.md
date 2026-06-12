# davidovic.dev

Personal portfolio of **Dimitrije Davidovic Vedda** — cloud/DevOps & data, New York, NY.

Plain static HTML/CSS (`site/`), served from a sealed S3 bucket behind CloudFront,
deployed by GitHub Actions via an OIDC-assumed IAM role (no stored credentials),
infrastructure as Terraform (`infra/`). No framework, no build step, no backend.

| | |
|---|---|
| `site/` | the site — edit, push, live |
| `infra/` | S3 + CloudFront + ACM + Route 53 + deploy role |
| `.github/workflows/deploy.yml` | push → S3 sync → CloudFront invalidation |
