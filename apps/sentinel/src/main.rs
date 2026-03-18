use std::io::{BufWriter, Write};
use std::net::TcpListener;

fn env_or(key: &str, fallback: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| fallback.to_string())
}

fn metrics_response() -> String {
    let body = [
        "# HELP sentinel_up Whether the sentinel service is running.",
        "# TYPE sentinel_up gauge",
        "sentinel_up 1",
        "",
    ]
    .join("\n");

    format!(
        "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\nContent-Length: {}\r\n\r\n{}",
        body.len(),
        body
    )
}

fn main() {
    let interface = env_or("SENTINEL_INTERFACE", "eth0");
    let port: u16 = env_or("SENTINEL_PORT", "9090")
        .parse()
        .expect("SENTINEL_PORT must be a valid port number");

    eprintln!("[sentinel] interface={interface} metrics=:{port}");
    eprintln!("[sentinel] packet capture not yet implemented");

    let addr = format!("0.0.0.0:{port}");
    let listener = TcpListener::bind(&addr).unwrap_or_else(|e| {
        eprintln!("[sentinel] failed to bind {addr}: {e}");
        std::process::exit(1);
    });

    eprintln!("[sentinel] listening on {addr}");

    for stream in listener.incoming().flatten() {
        let response = metrics_response();
        let mut writer = BufWriter::new(&stream);
        let _ = writer.write_all(response.as_bytes());
    }
}
