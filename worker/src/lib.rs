use worker::{event, Context, Env, Fetch, Headers, Request, Response, Result, Url};

const KNOWN_BRANCHES: &[&str] = &["macos", "vps"];
const GITHUB_RAW_BASE: &str = "https://raw.githubusercontent.com/rifuki/dotfiles";

fn parse_path(path: &str) -> (String, String) {
    let path = path.trim_start_matches('/');
    let segments: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();

    match segments.as_slice() {
        [] => ("main".to_string(), "install.sh".to_string()),
        [first] if KNOWN_BRANCHES.contains(first) => {
            (first.to_string(), "install.sh".to_string())
        }
        [file] => ("main".to_string(), file.to_string()),
        [branch, rest @ ..] if KNOWN_BRANCHES.contains(branch) => {
            (branch.to_string(), rest.join("/"))
        }
        segments => ("main".to_string(), segments.join("/")),
    }
}

#[event(fetch)]
async fn main(req: Request, _env: Env, _ctx: Context) -> Result<Response> {
    console_error_panic_hook::set_once();

    let url = req.url()?;
    let path = url.path();
    let (branch, file) = parse_path(path);

    let upstream = format!("{}/{}/{}", GITHUB_RAW_BASE, branch, file);
    let mut upstream_resp = Fetch::Url(upstream.parse::<Url>()?).send().await?;

    let status = upstream_resp.status_code();
    if status == 404 {
        return Response::error(format!("Not found: /{}/{}", branch, file), 404);
    }

    let body = upstream_resp.bytes().await?;
    let headers = Headers::new();
    headers.set("Content-Type", "text/plain; charset=utf-8")?;
    headers.set("Cache-Control", "no-cache")?;

    Ok(Response::from_bytes(body)?.with_headers(headers).with_status(status))
}
