use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug)]
struct SystemInfo {
    name: String,
    version: String,
}

impl SystemInfo {
    fn new() -> Self {
        SystemInfo {
            name: "IM Server".to_string(),
            version: "0.1.0".to_string(),
        }
    }

    fn to_json(&self) -> String {
        format!(r#"{{"name":"{}","version":"{}"}}"#, self.name, self.version)
    }
}

struct Conversation {
    id: String,
    title: String,
    last_msg: String,
    time: String,
    unread_count: i32,
    conversation_type: String,
    message_type: String,
    is_muted: bool,
}

fn get_conversations() -> Vec<Conversation> {
    vec![
        Conversation {
            id: "1".to_string(),
            title: "壹贰叁".to_string(),
            last_msg: "已被接收".to_string(),
            time: "3月16日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "transfer".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "2".to_string(),
            title: "付总".to_string(),
            last_msg: "我之前退了".to_string(),
            time: "3月14日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "3".to_string(),
            title: "鸭子🦆 (6.21)".to_string(),
            last_msg: "嗯".to_string(),
            time: "3月13日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "sticker".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "4".to_string(),
            title: "包子".to_string(),
            last_msg: "嗯".to_string(),
            time: "3月13日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "image".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "5".to_string(),
            title: "杨博".to_string(),
            last_msg: "噢噢，时间挺快的，明年你们也要出来实习了".to_string(),
            time: "3月12日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "6".to_string(),
            title: "2025区块链技能大赛备赛群".to_string(),
            last_msg: "王刻奇老师: 🤝".to_string(),
            time: "3月8日".to_string(),
            unread_count: 5,
            conversation_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: true,
        },
        Conversation {
            id: "7".to_string(),
            title: "18汽修徐叙敏".to_string(),
            last_msg: "".to_string(),
            time: "3月2日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "sticker".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "8".to_string(),
            title: "214".to_string(),
            last_msg: "23网新2罗敏颐: 不管了".to_string(),
            time: "2月28日".to_string(),
            unread_count: 0,
            conversation_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "9".to_string(),
            title: "创新创业项目交流".to_string(),
            last_msg: "龚芳海老师: 今天是20260228，祝创新创业项目…".to_string(),
            time: "2月28日".to_string(),
            unread_count: 12,
            conversation_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "10".to_string(),
            title: "小韩".to_string(),
            last_msg: "四下单词".to_string(),
            time: "2月21日".to_string(),
            unread_count: 0,
            conversation_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
    ]
}

fn conversations_to_json(conversations: &Vec<Conversation>) -> String {
    let mut json = "[".to_string();
    for (i, conv) in conversations.iter().enumerate() {
        if i > 0 {
            json.push(',');
        }
        json.push_str(&format!(
            r#"{{"id":"{}","title":"{}","lastMsg":"{}","time":"{}","unreadCount":{},"type":"{}","messageType":"{}","isMuted":{}}}"#,
            conv.id,
            conv.title,
            conv.last_msg,
            conv.time,
            conv.unread_count,
            conv.conversation_type,
            conv.message_type,
            if conv.is_muted { "true" } else { "false" }
        ));
    }
    json.push(']');
    json
}

fn handle_request(mut stream: TcpStream) {
    let mut buffer = [0; 1024];
    stream.read(&mut buffer).unwrap();

    let request = String::from_utf8_lossy(&buffer);

    let response = if request.starts_with("GET /v HTTP/1.1") || request.starts_with("GET /v\r") {
        let system_info = SystemInfo::new();
        format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
            system_info.to_json().len(),
            system_info.to_json()
        )
    } else if request.starts_with("GET /conversation HTTP/1.1") || request.starts_with("GET /conversation\r") {
        let conversations = get_conversations();
        let json = conversations_to_json(&conversations);
        format!(
            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
            json.len(),
            json
        )
    } else {
        "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\nContent-Length: 9\r\n\r\nNot Found".to_string()
    };

    stream.write(response.as_bytes()).unwrap();
    stream.flush().unwrap();
}

fn get_local_ip() -> String {
    "127.0.0.1".to_string()
}

fn main() {
    let ip = get_local_ip();
    let port = 3000;

    println!("Server starting on http://{}:{}", ip, port);
    println!("You can access the system info at http://{}:{}/v", ip, port);

    let listener = TcpListener::bind(format!("{}:{}", ip, port)).unwrap();

    println!("Server is running. Press Ctrl+C to stop.");

    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                handle_request(stream);
            }
            Err(e) => {
                eprintln!("Error: {}", e);
            }
        }
    }
}
