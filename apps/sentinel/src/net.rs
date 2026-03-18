use etherparse::SlicedPacket;
use serde::Serialize;
use std::fmt;
use std::net::Ipv4Addr;

#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Event {
    DnsQuery {
        src: String,
        domain: String,
    },
    TcpConnect {
        src: String,
        dst: String,
        dport: u16,
    },
}

impl fmt::Display for Event {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match serde_json::to_string(self) {
            Ok(json) => write!(f, "{json}"),
            Err(_) => write!(f, "{self:?}"),
        }
    }
}

pub struct PacketInfo {
    pub len: usize,
    pub is_tcp_syn: bool,
    pub is_dns: bool,
    pub src_ip: Option<Ipv4Addr>,
}

pub fn parse_packet(data: &[u8]) -> Option<(PacketInfo, Option<Event>)> {
    let packet = SlicedPacket::from_ethernet(data).ok()?;

    let (src_ip, dst_ip) = match &packet.net {
        Some(etherparse::NetSlice::Ipv4(ipv4)) => {
            let h = ipv4.header();
            (
                Some(Ipv4Addr::from(h.source())),
                Some(Ipv4Addr::from(h.destination())),
            )
        }
        _ => (None, None),
    };

    let mut info = PacketInfo {
        len: data.len(),
        is_tcp_syn: false,
        is_dns: false,
        src_ip,
    };

    let mut event = None;

    match &packet.transport {
        Some(etherparse::TransportSlice::Tcp(tcp)) => {
            if tcp.syn() && !tcp.ack() {
                info.is_tcp_syn = true;
                if let (Some(src), Some(dst)) = (src_ip, dst_ip) {
                    event = Some(Event::TcpConnect {
                        src: src.to_string(),
                        dst: dst.to_string(),
                        dport: tcp.destination_port(),
                    });
                }
            }
        }
        Some(etherparse::TransportSlice::Udp(udp)) => {
            if udp.destination_port() == 53 {
                info.is_dns = true;
                let payload = udp.payload();
                if let Some(domain) = parse_dns_query(payload) {
                    if let Some(src) = src_ip {
                        event = Some(Event::DnsQuery {
                            src: src.to_string(),
                            domain,
                        });
                    }
                }
            }
        }
        _ => {}
    }

    Some((info, event))
}

fn parse_dns_query(data: &[u8]) -> Option<String> {
    // skip DNS header (12 bytes), then read QNAME
    if data.len() < 13 {
        return None;
    }

    let mut pos = 12;
    let mut labels = Vec::new();

    loop {
        if pos >= data.len() {
            return None;
        }
        let len = data[pos] as usize;
        if len == 0 {
            break;
        }
        pos += 1;
        if pos + len > data.len() {
            return None;
        }
        labels.push(String::from_utf8_lossy(&data[pos..pos + len]).to_string());
        pos += len;
    }

    if labels.is_empty() {
        None
    } else {
        Some(labels.join("."))
    }
}
