# AI Chatbot Configuration Guide

## Overview
The ShopMate AI Assistant is a chatbot powered by Google Gemini API that helps customers with product search, shopping assistance, and order support.

## Prerequisites

### 1. AI User Account
The AI chatbot requires a dedicated user account in the database with **UserID = 23**.

**To create the AI user:**
```sql
-- Run this SQL script in your database
cd SalesApp
sqlcmd -S localhost -U sa -P 'YourPassword' -d SalesAppDB -i create_ai_user.sql
```

Or use the Docker command:
```bash
docker exec salesapp-sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrong@Passw0rd' \
  -d SalesAppDB -i /tmp/create_ai_user.sql -C
```

### 2. Google Gemini API Key
The AI chatbot uses Google Gemini API for natural language processing.

**Get your API key:**
1. Visit: https://makersuite.google.com/app/apikey
2. Create a new API key
3. Copy the key

**Configure the API key:**

**Option 1: Environment Variable (Recommended for Production)**
```bash
export GEMINI_API_KEY="your-gemini-api-key-here"
```

**Option 2: Application Properties (For Development)**
```yaml
# application.yaml
gemini:
  api:
    key: your-gemini-api-key-here
```

**Option 3: Docker Environment**
```yaml
# docker-compose.yml
services:
  backend:
    environment:
      - GEMINI_API_KEY=your-gemini-api-key-here
```

## Architecture

### AI User Configuration
- **UserID**: 23 (hardcoded in `ChatMessageService.java`)
- **Username**: ShopMate AI Assistant
- **Email**: ai-assistant@shopmate.com
- **Role**: AI (from `RoleEnum`)
- **Purpose**: Represents the AI bot in chat conversations

### How It Works

1. **User sends message** → Chat API receives request
2. **SmartAIService analyzes** → Determines user intent
3. **API calls (if needed)** → Searches products, checks orders
4. **Gemini generates response** → Natural language reply
5. **Response sent back** → Via WebSocket to user

### Key Components

**Backend Services:**
- `ChatMessageService` - Handles chat messages
- `SmartAIService` - Intent analysis + API integration
- `GeminiService` - Google Gemini API calls
- `GeminiTrainingService` - AI training data

**Frontend:**
- `ai-chat.html` - Modern chat UI
- WebSocket connection - Real-time messaging

## API Endpoints

### Check AI Status
```bash
GET http://localhost:8080/v1/chat/ai/status

Response:
{
  "aiUserId": 23,
  "status": "active",
  "features": [
    "Product Search",
    "Shopping Assistant",
    "Order Support",
    "General Queries"
  ],
  "timestamp": "2025-11-09T15:32:45.890Z"
}
```

### Send Message to AI
```bash
POST http://localhost:8080/v1/chat/send
Content-Type: application/json

{
  "userID": 1,
  "receiverID": 23,
  "message": "Tìm laptop Dell"
}

Response:
{
  "messageID": 123,
  "userID": 23,
  "receiverID": 1,
  "message": "Dạ, em tìm thấy 5 sản phẩm laptop Dell...",
  "sentAt": "2025-11-09T15:35:00",
  "forwardedToHuman": false
}
```

### Get Chat History
```bash
GET http://localhost:8080/v1/chat/history?userId=1&receiverId=23

Response:
{
  "messages": [
    {
      "messageID": 123,
      "userID": 1,
      "message": "Tìm laptop Dell",
      "sentAt": "2025-11-09T15:35:00"
    },
    {
      "messageID": 124,
      "userID": 23,
      "message": "Dạ, em tìm thấy 5 sản phẩm...",
      "sentAt": "2025-11-09T15:35:01"
    }
  ]
}
```

## WebSocket Connection

### Connect to Chat
```javascript
// Connect to WebSocket
const socket = new SockJS('http://localhost:8080/ws');
const stompClient = Stomp.over(socket);

stompClient.connect({}, function(frame) {
    console.log('Connected: ' + frame);
    
    // Subscribe to receive messages
    stompClient.subscribe('/topic/messages', function(message) {
        const chatMessage = JSON.parse(message.body);
        displayMessage(chatMessage);
    });
});

// Send message
function sendMessage() {
    const message = {
        userID: currentUserId,
        receiverID: 23, // AI User ID
        message: "Hello AI!"
    };
    
    stompClient.send("/app/chat", {}, JSON.stringify(message));
}
```

## Features

### 1. Product Search
AI can search for products in real-time:
```
User: "Tìm laptop Dell giá dưới 20 triệu"
AI: "Dạ, em tìm thấy 3 sản phẩm laptop Dell trong khoảng giá dưới 20 triệu:
     1. Dell Inspiron 15 - 18,500,000đ
     2. Dell Latitude 3420 - 19,200,000đ
     3. Dell Vostro 3510 - 17,800,000đ"
```

### 2. Shopping Assistant
Provides product recommendations and comparisons:
```
User: "So sánh iPhone 15 và Samsung S24"
AI: "Dạ, em xin phép so sánh 2 sản phẩm:
     - iPhone 15: 25,000,000đ - Camera 48MP, A16 Bionic
     - Samsung S24: 23,000,000đ - Camera 50MP, Snapdragon 8 Gen 3"
```

### 3. Order Support
Helps with order tracking and issues:
```
User: "Đơn hàng của tôi đang ở đâu?"
AI: "Dạ, để em kiểm tra đơn hàng cho anh/chị..."
```

### 4. Smart Escalation
Automatically forwards to human admin if AI can't help:
```javascript
if (aiCannotHandle) {
    message.setForwardedToHuman(true);
    // Admin will see this in forwarded messages
}
```

## Troubleshooting

### AI Not Responding
**Check:**
1. AI user exists in database (UserID = 23)
   ```sql
   SELECT * FROM Users WHERE UserID = 23;
   ```

2. Gemini API key is configured
   ```bash
   echo $GEMINI_API_KEY
   ```

3. Application logs for errors
   ```bash
   docker logs salesapp-backend | grep -i "error\|exception"
   ```

### WebSocket Connection Failed
**Check:**
1. WebSocket endpoints are public in SecurityConfig
   ```java
   "/ws/**", "/app/**", "/topic/**"
   ```

2. CORS configuration allows your domain
   ```java
   corsConfiguration.addAllowedOrigin("http://your-domain.com");
   ```

### AI Responses Are Slow
**Solutions:**
1. Check Gemini API rate limits
2. Optimize product search queries
3. Enable caching for frequent queries
4. Use async processing

## Security Considerations

### 1. Public Endpoints
Chat endpoints are public to allow guest users:
```java
private final String[] PUBLIC_ENDPOINTS = {
    "/v*/chat/**",
    "/ws/**",
    "/*.html"
};
```

### 2. Rate Limiting
Implement rate limiting to prevent abuse:
```java
// TODO: Add rate limiting
@RateLimiter(name = "chatbot", fallbackMethod = "rateLimitFallback")
public ChatMessageResponse sendMessage(ChatMessageRequest request) {
    // ...
}
```

### 3. Input Validation
Always validate and sanitize user input:
```java
if (request.getMessage() == null || request.getMessage().trim().isEmpty()) {
    throw new RuntimeException("Message cannot be empty");
}
```

## Access URLs

- **AI Chat UI**: http://3.27.207.79:8080/ai-chat.html
- **AI Status**: http://3.27.207.79:8080/v1/chat/ai/status
- **WebSocket**: ws://3.27.207.79:8080/ws

## Configuration Files

1. **Backend**:
   - `ChatMessageService.java` - AI_USER_ID = 23
   - `SecurityConfig.java` - Public endpoints
   - `application.yaml` - Gemini API key

2. **Database**:
   - `create_ai_user.sql` - AI user creation script

3. **Frontend**:
   - `ai-chat.html` - Chat interface
   - SockJS + STOMP - WebSocket library

## Monitoring

### Check AI Health
```bash
curl http://localhost:8080/v1/chat/ai/status
```

### View Chat Logs
```bash
docker logs salesapp-backend | grep "ChatMessageService"
```

### Database Queries
```sql
-- Count AI messages
SELECT COUNT(*) FROM ChatMessages WHERE UserID = 23 OR ReceiverID = 23;

-- Recent AI conversations
SELECT TOP 10 * FROM ChatMessages 
WHERE UserID = 23 OR ReceiverID = 23 
ORDER BY SentAt DESC;

-- Messages forwarded to human
SELECT * FROM ChatMessages WHERE ForwardedToHuman = 1;
```

## Next Steps

1. **Configure Gemini API key** (required for AI to work)
2. **Test the chat UI**: http://3.27.207.79:8080/ai-chat.html
3. **Monitor AI responses** and improve training data
4. **Add more features** (order tracking, payment help, etc.)
5. **Implement rate limiting** for production use

## Support

If you encounter issues:
1. Check application logs
2. Verify AI user exists (ID=23)
3. Confirm Gemini API key is set
4. Test endpoints manually with curl
5. Review this guide's troubleshooting section
