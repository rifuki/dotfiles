use worker::{event, Context, Env, Fetch, Headers, Request, Response, Result, Url};

const GITHUB_RAW_BASE: &str = "https://raw.githubusercontent.com/rifuki/dotfiles/main";

// Every path maps to the same path on main; "/" is the installer.
fn repo_path(path: &str) -> String {
    let path = path.trim_matches('/');
    if path.is_empty() {
        "install.sh".to_string()
    } else {
        path.to_string()
    }
}

#[event(fetch)]
async fn main(req: Request, _env: Env, _ctx: Context) -> Result<Response> {
    console_error_panic_hook::set_once();

    let file = repo_path(req.url()?.path());
    let upstream = format!("{}/{}", GITHUB_RAW_BASE, file);
    let mut upstream_resp = Fetch::Url(upstream.parse::<Url>()?).send().await?;

    let status = upstream_resp.status_code();
    if status == 404 {
        return Response::error(format!("Not found: /{}", file), 404);
    }

    let body = upstream_resp.bytes().await?;
    let headers = Headers::new();
    headers.set("Content-Type", "text/plain; charset=utf-8")?;
    headers.set("Cache-Control", "no-cache")?;

    Ok(Response::from_bytes(body)?.with_headers(headers).with_status(status))
}
