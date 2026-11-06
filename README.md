<p align="center">
  <a href="https://backlnk.com/developers"><img src="https://backlnk.com/icon.svg" width="72" height="72" alt="BACKLNK"></a>
</p>

<h1 align="center">BACKLNK MCP server</h1>

<p align="center">
  <strong>Free technical SEO, AEO, LLMO and GEO checks for AI agents: check a page, fix it, then verify the fix.<br>
  Evidence for every finding, most important first. Remote MCP server, free API key.</strong>
</p>

<p align="center">
  <a href="https://backlnk.com/developers">Get a free API key</a> ·
  <a href="#connect-your-agent">Connect your agent</a> ·
  <a href="#tools">Tools</a> ·
  <a href="#checks">Checks</a> ·
  <a href="#rest-api">REST API</a>
</p>

---

BACKLNK is a remote [Model Context Protocol](https://modelcontextprotocol.io) server. It gives Claude Code, Cursor,
VS Code and other MCP clients the same evidence-based checks that run on [backlnk.com](https://backlnk.com): meta tags
and social previews, page structure, structured data, AI crawler access in robots.txt, redirects and headers, sitemaps,
indexability, hreflang, internal links, duplicate content, images, llms.txt and page speed.

Every finding comes with its evidence (the URL, the exact excerpt and where it was found) and a recommendation, most
important first. Your agent fixes the code, and after you deploy, `verify_fixes` re-runs the same check and tells you
what is **fixed**, what is **new**, what is **still open** and what **could not be re-checked**.

| | |
| --- | --- |
| **Endpoint** | `https://backlnk.com/mcp` (Streamable HTTP, stateless) |
| **Authentication** | Free API key: `Authorization: Bearer bk_...` (or `X-API-Key: bk_...`) |
| **Price** | Free. 100 checks per key per 24 hours, plus a fair-use hourly limit |
| **Official MCP Registry** | [`com.backlnk/backlnk`](https://registry.modelcontextprotocol.io/v0/servers?search=com.backlnk) |
| **Documentation** | [backlnk.com/developers](https://backlnk.com/developers) |

> This repository holds the documentation, client configuration examples and the registry entry. The server itself
> runs at backlnk.com; there is nothing to install.

## Get a key

1. Open [backlnk.com/developers](https://backlnk.com/developers) and enter your e-mail address.
2. Click the link in the confirmation e-mail, then press the button on the page it opens.
3. Your key (`bk_...`) is shown **once**. Copy it and keep it somewhere safe.

Requesting a new key later replaces the old one.

## Connect your agent

### Claude Code

```bash
claude mcp add --transport http backlnk https://backlnk.com/mcp --header "Authorization: Bearer YOUR_KEY"
```

### Cursor

Add to `~/.cursor/mcp.json` (all projects) or `.cursor/mcp.json` (one project). See
[`examples/cursor-mcp.json`](examples/cursor-mcp.json).

```json
{
  "mcpServers": {
    "backlnk": {
      "url": "https://backlnk.com/mcp",
      "headers": { "Authorization": "Bearer YOUR_KEY" }
    }
  }
}
```

### VS Code

Add to `.vscode/mcp.json`. VS Code asks for the key once and stores it securely, so the file can be committed. See
[`examples/vscode-mcp.json`](examples/vscode-mcp.json).

```json
{
  "inputs": [{ "type": "promptString", "id": "backlnk-api-key", "description": "BACKLNK API key", "password": true }],
  "servers": {
    "backlnk": {
      "type": "http",
      "url": "https://backlnk.com/mcp",
      "headers": { "Authorization": "Bearer ${input:backlnk-api-key}" }
    }
  }
}
```

### Other clients

Any MCP client that supports remote servers over Streamable HTTP works: point it at `https://backlnk.com/mcp` and send
the key in the `Authorization` header (`Bearer bk_...`). Clients that can only forward a plain header can use
`X-API-Key: bk_...` instead.

## Try it

Ask your agent:

> Use BACKLNK to check https://example.com/pricing. Fix the issues it finds in this repository, most important first.
> When I've deployed, verify the fixes.

The loop:

1. **Check:** `run_checks` on the page's public URL. You get the issues and warnings, most important first, each with
   evidence and a recommendation.
2. **Fix:** the agent edits your templates, metadata, structured data or server configuration.
3. **Verify:** once the change is deployed to that URL, `verify_fixes` with each audit id. It re-runs the check fresh
   and compares: fixed, new, still open, not re-checked.

A finding counts as fixed only when the re-check assessed the same rule and found no problem. If the re-check could not
assess it, BACKLNK says so instead of claiming a fix.

## Tools

| Tool | What it does | Key |
| --- | --- | --- |
| `list_checks` | Lists every check (id, what it looks at, its scope and limits). | yes |
| `run_checks` | Runs checks on one public URL and waits up to about 40 seconds. Returns per check its state, summary, counts and the issues and warnings to fix, plus audit ids. Default set: `meta-tags`, `page-structure`, `ai-crawler-access`, `redirects-headers`, `entity-schema`. | yes |
| `get_report` | The compact report of an earlier check. `detail: "actions"` (default) for issues and warnings, `"all"` for every finding. | yes |
| `verify_fixes` | Re-runs the same check fresh on the same URL and options and returns the comparison with the original run. | yes |
| `ai_crawler_policy` | Builds robots.txt lines that allow or block AI crawlers from BACKLNK's reviewed crawler list, with what each line does and warnings. Presets: `block-training`, `block-ai`, `allow-all`, or decide per purpose and per crawler. | yes |
| `usage` | How many checks the key has used and has left today and this hour. | yes |

Listing the tools (`tools/list`) works without a key; calling them needs one.

**Arguments**

- `run_checks`: `url` (required), `checks` (check ids, optional), `mode` (`Source`, `Rendered` or `Auto`), `fresh`
  (re-run even if the same check ran very recently).
- `get_report`: `audit_id` (required), `detail` (`actions` or `all`).
- `verify_fixes`: `audit_id` (required).
- `ai_crawler_policy`: `preset`, or `purposes` (allow or block per purpose) and `crawlers` (per token, e.g.
  `{ "GPTBot": "allow" }`).

Status `NotAssessed` means a check could not determine the result: it is not a pass. Only `Issue` and `Warning` findings
need action.

## Checks

| Id | Check | Scope |
| --- | --- | --- |
| `meta-tags` | Meta & social preview | One page and its share image. |
| `page-structure` | Structure & readability | One page. |
| `entity-schema` | Schema & entities | One page; up to 15 sameAs destinations are checked for reachability. |
| `ai-crawler-access` | AI crawler access | robots.txt of the host plus one page's meta robots and X-Robots-Tag. |
| `redirects-headers` | Redirects & headers | The URL you enter plus its http:// and www / non-www variants. |
| `image-seo` | Image SEO | One page; up to 60 image files measured. |
| `page-speed` | Page speed | One page, two lab runs (mobile and desktop). |
| `indexability` | Indexability | Up to 50 URLs on one website, plus its robots.txt and sitemap. |
| `sitemap-hygiene` | Sitemap audit | Up to 20 sitemap files and 50,000 URLs; up to 40 destinations sampled. |
| `internal-links` | Internal links | Same host, up to 40 pages and depth 4. |
| `hreflang` | Hreflang | Same website, up to 40 pages reached through hreflang alternates and links. |
| `duplicate-content` | Duplicate & thin content | Same website, up to 40 pages. |
| `llms-txt-generate` | llms.txt draft | Reads up to 25 of your pages. |
| `llms-txt-validate` | llms.txt validation | Checks up to 60 listed links. |

The live list is always at [`https://backlnk.com/api/v1/checks`](https://backlnk.com/api/v1/checks). Two website checks that use a
hosted language model (Answer snippets, Intent & focus) run only on [backlnk.com](https://backlnk.com/tools), not through
the API or the MCP server.

## REST API

The same checks without MCP, for scripts and CI. Base URL `https://backlnk.com/api/v1`. See
[`examples/rest-api.sh`](examples/rest-api.sh).

```bash
# 1. Start a check (returns 202 with the audit id)
curl -X POST https://backlnk.com/api/v1/audits \
  -H "Authorization: Bearer YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"url":"https://example.com/","checks":["meta-tags","page-structure"]}'

# 2. Read the result (poll until "state" is Completed, Partial or Failed)
curl https://backlnk.com/api/v1/audits/AUDIT_ID -H "Authorization: Bearer YOUR_KEY"

# 3. After fixing the page: re-check and compare with the first run
curl -X POST https://backlnk.com/api/v1/audits/AUDIT_ID/verify -H "Authorization: Bearer YOUR_KEY"
```

| Method | Path | Key | |
| --- | --- | --- | --- |
| `GET` | `/checks` | no | The checks you can run. |
| `POST` | `/audits` | yes | Start checks on one URL: `{ "url", "checks": [ids], "mode"? , "options"? }`. An optional `Idempotency-Key` header makes retries safe. |
| `GET` | `/audits/{id}` | yes | State, summary, scores, coverage and findings, most important first (`?detail=actions` for issues and warnings only). |
| `POST` | `/audits/{id}/verify` | yes | Re-run fresh and compare with the original. |
| `GET` | `/audits/{id}/export?format=json\|csv` | yes | The full report (JSON) or the findings (CSV). |
| `GET` | `/usage` | yes | Today's and this hour's usage of the key. |
| `POST` | `/ai-crawler-policy` | no | robots.txt lines for AI crawlers from a preset or your choices. |

Errors are JSON, `{ "error": { "code", "message" } }`, with the matching HTTP status: 401 for a missing or revoked key,
429 with `Retry-After` when a limit is reached.

## Limits and fair use

- 100 checks per key in any 24 hours; results BACKLNK reuses from a very recent identical check are free.
- A fair-use hourly limit per key, and limits per website so no site is crawled too hard.
- BACKLNK only checks public pages. Private, local and internal addresses are refused.
- `GET /api/v1/usage` and the `usage` tool show what is left.

## Privacy

BACKLNK keeps your e-mail address with your key and deletes it if you ask
([contact](https://backlnk.com/contact)). Reports are private to the key that ran them and are never published or
indexed.

## Support

Questions, bugs or ideas: [open an issue](https://github.com/BACKLNK/backlnk-mcp/issues) or write to us at
[backlnk.com/contact](https://backlnk.com/contact).

## License

The documentation and examples in this repository are available under the [MIT License](LICENSE). The BACKLNK service
is free to use within its limits.
