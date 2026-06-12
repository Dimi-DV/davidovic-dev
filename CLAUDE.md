# davidovic.dev — public portfolio

Personal portfolio site for **Dimitrije Davidovic Vedda** (junior cloud/DevOps + data,
New York). Static HTML/CSS in `site/`, served from S3 behind CloudFront at the
apex `davidovic.dev` (+ `www`). No build system, no framework, no backend — edit HTML,
push, deployed.

## Hard rules

1. **THIS REPO IS PUBLIC.** Never copy, reference, or link anything from `~/serb-ops`
   (the private job-search pipeline): no tracker data, no salary info, no tailored CVs,
   no rubric/strategy, and never any link to any private subdomain of davidovic.dev. The
   only material that may cross over is what `CONTENT.md` explicitly whitelists.
2. **Ground truth applies to every public word.** All claims about skills, projects,
   metrics, and experience must be literally supported by `~/serb-ops/cv.md` and the
   verified proof points in `~/serb-ops/profile.md` (read-only sources). The anti-claims
   list there is binding here too — no "AWS Certified", no inflated metrics, no
   "production at scale", Triage is a portfolio project not a production system.
3. **Nothing goes live at the apex without Dimi's explicit review.** Workflow: deploy to
   the bucket → he reviews on the raw CloudFront URL → only then flip
   `enable_apex_dns = true` in `infra/` and apply. Content changes after launch: he
   reviews diffs before push.
4. The Route 53 zone for davidovic.dev is OWNED by `~/serb-ops/infra` (it also serves a
   subdomain). This repo's Terraform only does a `data` lookup of the zone by name and
   adds apex/www records — never create or modify the zone itself.
5. **Location is New York, NY (where he lives).** Everything public — the site,
   README, this repo's docs, the downloadable CV — presents New York, NY as the
   location, optionally with a generic "open to relocation" note. Never name a
   target city or tell a relocation-in-progress story. On location framing this
   rule overrides the ground-truth sources in rule 2; everything else there binds.

## Layout

| Path | What |
|------|------|
| `site/` | The static site (index.html + css + assets). What ships. |
| `CONTENT.md` | Content brief: sections, source material locations, whitelist. |
| `infra/main.tf` | S3 + CloudFront + ACM + apex DNS (gated) + GitHub-OIDC deploy role. |
| `.github/workflows/deploy.yml` | push → S3 sync → CloudFront invalidation (guarded on repo vars). |

## Launch sequence (one-time)

1. `gh repo create Dimi-DV/davidovic-dev --public --source=. --push`
2. `cd infra && terraform init && terraform apply` (zone lookup needs AWS creds; the
   GitHub OIDC provider already exists in the account — main.tf assumes it).
3. Set repo Variables from terraform output: `AWS_DEPLOY_ROLE_ARN`, `AWS_REGION`,
   `SITE_BUCKET`, `CF_DIST_ID`.
4. Author content per `CONTENT.md`, push, review at the `cloudfront_url` output.
5. On Dimi's approval: `terraform apply -var enable_apex_dns=true` → live.
