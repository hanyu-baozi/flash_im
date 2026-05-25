use serde::Serialize;

#[derive(Debug, Serialize)]
pub struct SystemInfo {
    pub name: String,
    pub version: String,
}

impl SystemInfo {
    pub fn new() -> Self {
        SystemInfo {
            name: "IM Server".to_string(),
            version: "0.1.0".to_string(),
        }
    }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct Conversation {
    pub id: String,
    pub title: String,
    pub last_msg: String,
    pub time: String,
    pub unread_count: i32,
    #[serde(rename = "type")]
    pub conv_type: String,
    pub message_type: String,
    pub is_muted: bool,
}

pub fn get_conversations() -> Vec<Conversation> {
    vec![
        Conversation {
            id: "1".to_string(),
            title: "壹贰叁 （备注学校，会统一通…".to_string(),
            last_msg: "已被接收".to_string(),
            time: "3月16日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "transfer".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "2".to_string(),
            title: "付总".to_string(),
            last_msg: "我之前退了".to_string(),
            time: "3月14日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "3".to_string(),
            title: "鸭子🦆 (6.21)".to_string(),
            last_msg: "嗯".to_string(),
            time: "3月13日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "sticker".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "4".to_string(),
            title: "包子".to_string(),
            last_msg: "嗯".to_string(),
            time: "3月13日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "image".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "5".to_string(),
            title: "杨博".to_string(),
            last_msg: "噢噢，时间挺快的，明年你们也要出来实习了".to_string(),
            time: "3月12日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "6".to_string(),
            title: "2025区块链技能大赛备赛群".to_string(),
            last_msg: "王刻奇老师: 🤝".to_string(),
            time: "3月8日".to_string(),
            unread_count: 5,
            conv_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: true,
        },
        Conversation {
            id: "7".to_string(),
            title: "18汽修徐叙敏".to_string(),
            last_msg: "".to_string(),
            time: "3月2日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "sticker".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "8".to_string(),
            title: "214".to_string(),
            last_msg: "23网新2罗敏颐: 不管了".to_string(),
            time: "2月28日".to_string(),
            unread_count: 0,
            conv_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "9".to_string(),
            title: "创新创业项目交流".to_string(),
            last_msg: "龚芳海老师: 今天是20260228，祝创新创业项目…".to_string(),
            time: "2月28日".to_string(),
            unread_count: 12,
            conv_type: "group".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
        Conversation {
            id: "10".to_string(),
            title: "小韩".to_string(),
            last_msg: "四下单词".to_string(),
            time: "2月21日".to_string(),
            unread_count: 0,
            conv_type: "single".to_string(),
            message_type: "text".to_string(),
            is_muted: false,
        },
    ]
}
