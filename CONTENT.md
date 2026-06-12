# Content brief — davidovic.dev

Audience: recruiters and hiring managers (New York + remote/international). Tone:
direct, technical, specific — show what was built, no "passionate", no buzzword soup.
Every claim ground-truth-checked (see CLAUDE.md rule 2).

Design: the site mirrors the **Triage design system** (Dimi's claude.ai/design project
"Triage Design System") — deep-navy instrument-panel surfaces, mint `#00E5BE` accent
used sparingly, Geist + Geist Mono (self-hosted woff2), sharp 4px corners, borders
carry structure, pills are the only round elements. Sections are collapsed
`<details>` panels that expand on click.

## Sections (v1)

1. **Hero** — Dimitrije Davidovic Vedda (mint terminal period, mirroring the Triage
   wordmark) · mono uppercase eyebrow "cloud · devops · data" · location "New York, NY"
   with a mint status pill "open to relocation". Circular headshot avatar
   (`site/assets/avatar.jpg` — EXIF-stripped, cropped). One-line
   identity: economics grad → ops analyst → self-taught AWS builder. Native English +
   Serbian. Links: GitHub (Dimi-DV), LinkedIn (dimitrije-vedda), email
   (dimitrije.vedda@outlook.com), CV download.
2. **Triage** (flagship) — autonomous incident-response agent on AWS Bedrock AgentCore:
   the alarm → investigate → diagnose → Slack loop; Cedar-gated writes at the Gateway;
   eval corpus (9 scenarios, FIS + Terraform misconfigs, Match on all 9 most-recent
   runs); the scenario-03 four-run debugging arc as the story. Architecture diagram
   if source repo has one.
3. **Infrastructure projects** — Terraform multi-AZ VPC module (18 resources/deploy,
   remote state S3+DynamoDB); CI/CD GitHub Actions → ECR → ECS Fargate with OIDC (no
   long-lived keys).
4. **Data engineering story** — Il Mulino: Python pipeline standardizing multi-location
   sales data (sentence-transformers, TF-IDF) into a master sales sheet; presented to
   CEO/Director of Finance; monthly Excel↔POS reconciliation. INTERNAL work — never
   frame as customer-facing.
5. **About / contact** — based in New York, NY and open to relocation; BBA Economics
   (Baruch/CUNY 2023), the ops-analyst → self-taught cloud arc, what he's looking
   for (early-career cloud/data roles). Keep the relocation note generic — "open to
   relocation", no target city named anywhere on the site.
6. **Footer colophon** — "plain HTML/CSS on S3 + CloudFront · provisioned with
   Terraform · deployed by GitHub Actions (OIDC) · source" linking this repo. The
   site's own infrastructure is part of the portfolio — keep this line.

## Source material (read-only)

- `~/serb-ops/cv.md` — the factual ceiling for every claim.
- `~/serb-ops/profile.md` — verified proof points (§Proof points) + anti-claims list.
- `~/triage/` — the Triage repo (README, architecture).
- `~/triage-session-notes/` — build/deploy war stories (good narrative material;
  scrub anything personal before quoting).
- `~/devops-learning/` — the 60-day sprint structure.

## Whitelist (the ONLY serb-ops crossover allowed)

- Facts from cv.md / profile.md proof points, restated for a public audience.
- NOTHING else: no pipeline mechanics, no tracker, no rubric, no private-subdomain links.

## Public CV download

A generic (non-tailored) PDF rendered from cv.md — full name, EN; one page preferred,
but the full generic render runs two — trimming sections to fit is Dimi's call. Generate
with serb-ops' generate-pdf.mjs + cv-template.html (copy the rendered PDF in; do not
symlink across repos). The PDF's location line must match the site — New York, NY,
optionally with the same generic "open to relocation" note, never a target city —
even if that means adjusting the header for this render. The public render also
omits the phone number and the entire Crypto/Web3 independent-experience section
(Dimi, 2026-06-12).
