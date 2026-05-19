use std::io::{Read, Write};
use std::net::{TcpListener, TcpStream};

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

#[derive(Debug)]
struct Conversation {
    title: String,
    last_msg: String,
    time: String,
}

impl Conversation {
    fn new(title: String, last_msg: String, time: String) -> Self {
        Conversation {
            title,
            last_msg,
            time,
        }
    }

    fn to_json(&self) -> String {
        format!(
            r#"{{"title":"{}","lastMsg":"{}","time":"{}"}}"#,
            self.title, self.last_msg, self.time
        )
    }
}

fn get_mock_conversations() -> Vec<Conversation> {
    vec![
        Conversation::new("张三".to_string(), "晚上一起吃饭吗？".to_string(), "2026-04-25 18:30".to_string()),
        Conversation::new("李四".to_string(), "项目文档已发送".to_string(), "2026-04-25 17:45".to_string()),
        Conversation::new("王五".to_string(), "明天见！".to_string(), "2026-04-25 16:20".to_string()),
        Conversation::new("赵六".to_string(), "会议改到下午3点".to_string(), "2026-04-25 15:10".to_string()),
        Conversation::new("产品组".to_string(), "新版本需求评审".to_string(), "2026-04-25 14:30".to_string()),
        Conversation::new("技术部".to_string(), "服务器维护通知".to_string(), "2026-04-25 13:50".to_string()),
        Conversation::new("小美".to_string(), "设计稿已更新".to_string(), "2026-04-25 12:15".to_string()),
        Conversation::new("老板".to_string(), "周报记得提交".to_string(), "2026-04-25 11:00".to_string()),
        Conversation::new("HR部门".to_string(), "下月团建活动投票".to_string(), "2026-04-25 10:30".to_string()),
        Conversation::new("客户A".to_string(), "合同已签署完成".to_string(), "2026-04-25 09:45".to_string()),
        Conversation::new("运维组".to_string(), "数据库备份完成".to_string(), "2026-04-24 22:00".to_string()),
        Conversation::new("测试组".to_string(), "Bug修复验证通过".to_string(), "2026-04-24 19:30".to_string()),
        Conversation::new("小李".to_string(), "代码review完成".to_string(), "2026-04-24 17:00".to_string()),
        Conversation::new("财务部".to_string(), "报销单已审批".to_string(), "2026-04-24 15:20".to_string()),
        Conversation::new("市场部".to_string(), "活动方案讨论".to_string(), "2026-04-24 14:10".to_string()),
        Conversation::new("供应商B".to_string(), "发货单号已提供".to_string(), "2026-04-24 11:30".to_string()),
        Conversation::new("前端组".to_string(), "UI组件库更新".to_string(), "2026-04-24 10:00".to_string()),
        Conversation::new("后端组".to_string(), "API文档已同步".to_string(), "2026-04-23 18:45".to_string()),
        Conversation::new("客户B".to_string(), "需求变更确认".to_string(), "2026-04-23 16:30".to_string()),
        Conversation::new("行政部".to_string(), "办公用品采购清单".to_string(), "2026-04-23 14:00".to_string()),
    ]
}

fn conversations_to_json(conversations: &[Conversation]) -> String {
    let items: Vec<String> = conversations.iter().map(|c| c.to_json()).collect();
    format!("[{}]", items.join(","))
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
        let conversations = get_mock_conversations();
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
    println!("You can access conversations at http://{}:{}/conversation", ip, port);

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
