mod net;

use std::collections::HashSet;
use std::io::{BufWriter, Write};
use std::net::{Ipv4Addr, TcpListener};
use std::sync::{Arc, Mutex};
use std::thread;

struct Metrics {
    packets_total: u64,
    bytes_total: u64,
    dns_queries_total: u64,
    tcp_syn_total: u64,
    unique_sources: HashSet<Ipv4Addr>,
}

impl Metrics {
    fn new() -> Self {
        Self {
            packets_total: 0,
            bytes_total: 0,
            dns_queries_total: 0,
            tcp_syn_total: 0,
            unique_sources: HashSet::new(),
        }
    }

    fn render(&self) -> String {
        [
            "# HELP sentinel_up Whether the sentinel service is running.",
            "# TYPE sentinel_up gauge",
            "sentinel_up 1",
            "",
            "# HELP sentinel_packets_total Total packets captured.",
            "# TYPE sentinel_packets_total counter",
            &format!("sentinel_packets_total {}", self.packets_total),
            "",
            "# HELP sentinel_bytes_total Total bytes captured.",
            "# TYPE sentinel_bytes_total counter",
            &format!("sentinel_bytes_total {}", self.bytes_total),
            "",
            "# HELP sentinel_dns_queries_total Total DNS queries observed.",
            "# TYPE sentinel_dns_queries_total counter",
            &format!("sentinel_dns_queries_total {}", self.dns_queries_total),
            "",
            "# HELP sentinel_tcp_syn_total Total TCP connection attempts (SYN packets).",
            "# TYPE sentinel_tcp_syn_total counter",
            &format!("sentinel_tcp_syn_total {}", self.tcp_syn_total),
            "",
            "# HELP sentinel_unique_sources Number of unique source IPs observed.",
            "# TYPE sentinel_unique_sources gauge",
            &format!("sentinel_unique_sources {}", self.unique_sources.len()),
            "",
        ]
        .join("\n")
    }
}

fn env_or(key: &str, fallback: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| fallback.to_string())
}

fn capture_loop(interface: &str, metrics: Arc<Mutex<Metrics>>) {
    let mut cap = match pcap::Capture::from_device(interface) {
        Ok(cap) => match cap.promisc(true).immediate_mode(true).open() {
            Ok(cap) => cap,
            Err(e) => {
                eprintln!("[sentinel] failed to open capture on {interface}: {e}");
                return;
            }
        },
        Err(e) => {
            eprintln!("[sentinel] device {interface} not found: {e}");
            return;
        }
    };

    eprintln!("[sentinel] capturing on {interface}");

    while let Ok(packet) = cap.next_packet() {
        if let Some((info, event)) = net::parse_packet(packet.data) {
            let mut m = metrics.lock().unwrap();
            m.packets_total += 1;
            m.bytes_total += info.len as u64;

            if info.is_dns {
                m.dns_queries_total += 1;
            }
            if info.is_tcp_syn {
                m.tcp_syn_total += 1;
            }
            if let Some(src) = info.src_ip {
                m.unique_sources.insert(src);
            }
            drop(m);

            if let Some(event) = event {
                eprintln!("{event}");
            }
        }
    }
}

fn metrics_server(port: u16, metrics: Arc<Mutex<Metrics>>) {
    let addr = format!("0.0.0.0:{port}");
    let listener = TcpListener::bind(&addr).unwrap_or_else(|e| {
        eprintln!("[sentinel] failed to bind {addr}: {e}");
        std::process::exit(1);
    });

    eprintln!("[sentinel] metrics on {addr}");

    for stream in listener.incoming().flatten() {
        let body = metrics.lock().unwrap().render();
        let response = format!(
            "HTTP/1.1 200 OK\r\nContent-Type: text/plain; version=0.0.4\r\nContent-Length: {}\r\n\r\n{}",
            body.len(),
            body
        );
        let mut writer = BufWriter::new(&stream);
        let _ = writer.write_all(response.as_bytes());
    }
}

fn main() {
    let interface = env_or("SENTINEL_INTERFACE", "eth0");
    let port: u16 = env_or("SENTINEL_PORT", "9090")
        .parse()
        .expect("SENTINEL_PORT must be a valid port number");

    eprintln!("[sentinel] interface={interface} metrics=:{port}");

    let metrics = Arc::new(Mutex::new(Metrics::new()));

    let capture_metrics = Arc::clone(&metrics);
    let capture_interface = interface.clone();
    thread::spawn(move || capture_loop(&capture_interface, capture_metrics));

    metrics_server(port, metrics);
}
