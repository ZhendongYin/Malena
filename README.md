# AI Chat System

An enterprise-grade AI chat system built with Phoenix LiveView, supporting multiple AI models, role-based permissions, knowledge base integration, and real-time streaming responses.

## 🚀 Key Features

### 🤖 AI Chat
- **Multi-Model Support**: Supports Ollama, OpenAI, Claude, Gemini, and other AI models
- **Real-Time Streaming**: Real-time streaming of AI responses
- **Thinking Process Display**: Shows AI's thinking process with collapsible/expandable interface
- **Conversation History**: Complete conversation history management and storage

### 👥 User Management
- **Role-Based Permission System**: Supports Super Admin, HR Employee, and other roles
- **Department Management**: Multi-level department structure support
- **Granular Permission Control**: Fine-grained permissions based on roles and departments
- **Session Management**: Secure authentication system using Guardian

### 📝 Content Management
- **Prompt Management**: System-level prompt configuration to control AI behavior
- **Knowledge Base Integration**: Document upload and knowledge base querying
- **AI API Configuration**: Flexible configuration of different AI models and parameters

### 🎨 User Interface
- **Responsive Design**: Support for desktop and mobile devices
- **Dark/Light Theme**: Theme switching support
- **Modern UI**: Modern interface built with DaisyUI and Tailwind CSS
- **Real-Time Updates**: Real-time interface updates using Phoenix LiveView

## 🛠 Technology Stack

- **Backend**: Phoenix Framework (Elixir)
- **Frontend**: Phoenix LiveView + Tailwind CSS + DaisyUI
- **Database**: PostgreSQL
- **Authentication**: Guardian JWT
- **AI Integration**: HTTPoison (supports Ollama, OpenAI, Claude, Gemini)
- **Real-Time Communication**: Phoenix PubSub

## 📋 System Requirements

- Elixir 1.18+
- Erlang/OTP 26+
- PostgreSQL 12+
- Node.js 18+ (for frontend assets)

## 🚀 Quick Start

### 1. Clone the Project

```bash
git clone <repository-url>
cd ai_chat
```

### 2. Install Dependencies

```bash
# Install Elixir dependencies
mix deps.get

# Install frontend dependencies
cd assets && npm install && cd ..
```

### 3. Database Setup

```bash
# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Create seed data
mix run priv/repo/seeds.exs
```

### 4. Start Ollama (Optional)

If using Ollama as your AI model:

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Download a model (in another terminal)
ollama pull gemma3:1b
```

### 5. Start the Application

```bash
# Start Phoenix server
mix phx.server
```

Visit `http://localhost:4000` to get started.

## 👤 Default Accounts

The system comes with the following default accounts:

### Super Admin
- **Username**: admin@example.com
- **Password**: password123
- **Permissions**: All system permissions

### Other Roles
- HR Manager
- IT Manager  
- HR Employee

## 🔧 Configuration

### AI Model Configuration

1. Visit `/admin/ai-apis`
2. Add new AI API configurations
3. Set model parameters (temperature, max tokens, etc.)
4. Configure department/role scope

### Prompt Configuration

1. Visit `/admin/prompts`
2. Create system prompts
3. Set applicable scope (departments/roles)
4. Configure AI behavior and response style

### Knowledge Base Setup

1. Visit `/admin/knowledge-bases`
2. Upload document files
3. Configure processing status
4. Set access permissions

## 📁 Project Structure

```
lib/
├── ai_chat/                 # Core business logic
│   ├── accounts/           # User account management
│   ├── ai_apis.ex         # AI API management
│   ├── ai_client.ex       # AI client
│   ├── chat/              # Chat functionality
│   ├── knowledge_bases/   # Knowledge base
│   ├── organizations/     # Organization management
│   └── prompts.ex         # Prompt management
├── ai_chat_web/           # Web interface
│   ├── controllers/       # Controllers
│   ├── live/             # LiveView pages
│   ├── components/       # Reusable components
│   └── plugs/            # Plugs
└── mix/tasks/            # Custom Mix tasks
```

## 🎯 Core Features

### Chat System

- **Real-Time Conversation**: Support for real-time conversations with AI
- **Streaming Responses**: Real-time display of AI responses for better user experience
- **Thinking Process**: Display AI's thinking process (if supported by the model)
- **Conversation History**: Save and view conversation history

### Permission System

- **Role Management**: Support for creating and managing different roles
- **Permission Control**: Fine-grained functional permission control
- **Department Management**: Support for multi-level department structure
- **User Management**: Complete user lifecycle management

### AI Integration

- **Multi-Model Support**: Support for multiple AI models simultaneously
- **Model Switching**: Switch between different models
- **Parameter Configuration**: Configurable temperature, token count, and other parameters
- **Scope Control**: Model access control based on user roles

## 🔒 Security Features

- **JWT Authentication**: Secure authentication using Guardian
- **Permission Verification**: All operations include permission verification
- **Data Isolation**: Role-based data access isolation
- **Session Management**: Secure session management

## 📊 Monitoring and Logging

- **Real-Time Monitoring**: LiveView provides real-time system status
- **Detailed Logging**: Complete operation log recording
- **Error Tracking**: Detailed error information and stack traces
- **Performance Monitoring**: Database query and response time monitoring

## 🚀 Deployment

### Docker Deployment

```bash
# Build Docker image
docker build -t ai-chat .

# Run container
docker run -p 4000:4000 ai-chat
```

### Production Environment

```bash
# Set environment variables
export DATABASE_URL="postgres://user:password@localhost/ai_chat_prod"
export SECRET_KEY_BASE="your-secret-key"

# Compile production version
MIX_ENV=prod mix compile

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Start application
MIX_ENV=prod mix phx.server
```

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues or have questions, please:

1. Check the [Issues](../../issues) page
2. Create a new Issue
3. Contact the development team

## 🔄 Changelog

### v1.0.0
- Initial release
- Basic chat functionality
- User permission system
- AI model integration
- Knowledge base support

---

**Enjoy using AI Chat System!** 🎉