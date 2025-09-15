# AI Chat System

<div align="center">

![AI Chat System](https://img.shields.io/badge/AI-Chat%20System-blue?style=for-the-badge&logo=elixir)
![Phoenix](https://img.shields.io/badge/Phoenix-1.8+-red?style=for-the-badge&logo=elixir)
![Elixir](https://img.shields.io/badge/Elixir-1.15+-purple?style=for-the-badge&logo=elixir)
![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker)

*An enterprise-grade AI chat system built with Phoenix LiveView, supporting multiple AI models, role-based permissions, knowledge base integration, and real-time streaming responses.*

[🚀 Quick Start](#-quick-start) • [📖 Documentation](#-documentation) • [🐳 Docker](#-docker-deployment) • [🤝 Contributing](#-contributing)

</div>

## ✨ Key Features

### 🤖 **AI Chat Engine**
- **Multi-Model Support**: Ollama, OpenAI, Claude, Gemini, and more
- **Real-Time Streaming**: Live streaming of AI responses with typing indicators
- **Thinking Process Display**: Collapsible AI reasoning and thought processes
- **Conversation History**: Persistent chat history with search and filtering
- **Context Management**: Smart context retention across conversations

### 👥 **Advanced User Management**
- **Role-Based Access Control**: Super Admin, HR Manager, IT Manager, Employee roles
- **Department Hierarchy**: Multi-level organizational structure support
- **Granular Permissions**: Fine-grained access control per feature and department
- **Secure Authentication**: JWT-based authentication with Guardian
- **Session Management**: Secure session handling with configurable timeouts

### 📚 **Knowledge Base & Content**
- **Document Upload**: Support for PDF, DOC, TXT, and other formats
- **Vector Search**: Semantic search using pgvector for intelligent document retrieval
- **Prompt Management**: System-wide prompt templates and configurations
- **AI API Configuration**: Flexible model parameters and endpoint management
- **Content Processing**: Automated document parsing and indexing

### 🎨 **Modern User Interface**
- **Responsive Design**: Mobile-first design with desktop optimization
- **Dark/Light Themes**: Automatic theme switching with user preferences
- **Real-Time Updates**: Live interface updates using Phoenix LiveView
- **Accessibility**: WCAG compliant with keyboard navigation support
- **Progressive Web App**: Offline capabilities and mobile app-like experience

## 🛠 Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| **Backend** | Phoenix Framework (Elixir) | 1.8+ |
| **Frontend** | Phoenix LiveView + Tailwind CSS + DaisyUI | Latest |
| **Database** | PostgreSQL with pgvector | 15+ |
| **Authentication** | Guardian JWT | 2.3+ |
| **AI Integration** | HTTPoison + Req | 2.0+ |
| **Real-Time** | Phoenix PubSub | Built-in |
| **Background Jobs** | Oban | 2.15+ |
| **File Storage** | Waffle + S3/Local | 1.1+ |
| **Caching** | Redis | 7+ |

## 📋 System Requirements

### Development Environment
- **Elixir**: 1.15+
- **Erlang/OTP**: 26+
- **PostgreSQL**: 15+
- **Node.js**: 18+ (for asset compilation)
- **Redis**: 7+ (for caching and sessions)

### Production Environment
- **Memory**: 2GB+ RAM recommended
- **Storage**: 10GB+ for application and database
- **CPU**: 2+ cores recommended
- **Network**: HTTPS support required

## 🚀 Quick Start

### 🐳 **Docker (Recommended)**

The fastest way to get started is using Docker:

```bash
# Clone the repository
git clone <repository-url>
cd ai_chat

# Run the automated setup script
./docker-setup.sh
```

The setup script will:
- Build the Docker image
- Start PostgreSQL and Redis services
- Run database migrations
- Start the application
- Generate a secure secret key

**Access the application at:** `http://localhost:4000`

### 🛠 **Manual Setup**

If you prefer to run the application locally:

#### 1. Prerequisites
```bash
# Install Elixir (using asdf recommended)
asdf install elixir 1.15.7-otp-26
asdf install erlang 26.2.1

# Install Node.js
asdf install nodejs 20.10.0

# Install PostgreSQL and Redis
# macOS with Homebrew:
brew install postgresql redis
brew services start postgresql
brew services start redis
```

#### 2. Clone and Setup
```bash
# Clone the repository
git clone <repository-url>
cd ai_chat

# Install dependencies
mix deps.get
cd assets && npm install && cd ..

# Setup database
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

#### 3. Start the Application
```bash
# Start Phoenix server
mix phx.server
```

### 🤖 **AI Model Setup (Optional)**

#### Ollama (Local AI)
```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve

# Download a model (in another terminal)
ollama pull gemma2:2b
ollama pull llama3.2:3b
```

#### OpenAI/Claude/Gemini
Configure your API keys in the admin panel at `/admin/ai-apis` after starting the application.

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

## 🐳 Docker Deployment

### **Development with Docker Compose**

```bash
# Start all services (app, database, redis)
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

### **Production Docker Deployment**

#### 1. Build Production Image
```bash
# Build the image
docker build -t ai-chat:latest .

# Tag for registry (optional)
docker tag ai-chat:latest your-registry/ai-chat:latest
```

#### 2. Run with Environment Variables
```bash
docker run -d \
  --name ai-chat \
  -p 4000:4000 \
  -e SECRET_KEY_BASE="your-secret-key-base" \
  -e DATABASE_URL="ecto://user:password@host:5432/database" \
  -e PHX_HOST="your-domain.com" \
  -e REDIS_URL="redis://host:6379" \
  ai-chat:latest
```

#### 3. Docker Compose for Production
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  app:
    image: ai-chat:latest
    ports:
      - "4000:4000"
    environment:
      - MIX_ENV=prod
      - SECRET_KEY_BASE=${SECRET_KEY_BASE}
      - DATABASE_URL=ecto://postgres:${DB_PASSWORD}@db:5432/ai_chat_prod
      - REDIS_URL=redis://redis:6379
      - PHX_HOST=${PHX_HOST}
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    environment:
      - POSTGRES_DB=ai_chat_prod
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
```

### **Environment Variables**

| Variable | Description | Required | Default |
|----------|-------------|----------|---------|
| `SECRET_KEY_BASE` | Phoenix secret key | ✅ | - |
| `DATABASE_URL` | PostgreSQL connection string | ✅ | - |
| `REDIS_URL` | Redis connection string | ❌ | - |
| `PHX_HOST` | Application hostname | ❌ | localhost |
| `PORT` | Application port | ❌ | 4000 |
| `MIX_ENV` | Environment | ❌ | prod |

### **Production Environment (Manual)**

```bash
# Set environment variables
export SECRET_KEY_BASE="$(mix phx.gen.secret)"
export DATABASE_URL="postgres://user:password@localhost/ai_chat_prod"
export PHX_HOST="your-domain.com"

# Compile production version
MIX_ENV=prod mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy

# Run migrations
MIX_ENV=prod mix ecto.migrate

# Start application
MIX_ENV=prod mix phx.server
```

## 📖 Documentation

### **API Documentation**
- **Admin API**: `/admin` - Complete administrative interface
- **Chat API**: `/chat` - Real-time chat functionality
- **User Management**: `/admin/users` - User and role management
- **AI Configuration**: `/admin/ai-apis` - AI model configuration

### **Architecture Overview**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Phoenix       │    │   PostgreSQL    │    │     Redis       │
│   LiveView      │◄──►│   + pgvector    │    │   (Caching)     │
│   (Frontend)    │    │   (Database)    │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AI Models     │    │   File Storage  │    │   Background    │
│   (Ollama/      │    │   (Waffle)      │    │   Jobs (Oban)   │
│   OpenAI/etc)   │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Key Components**
- **`AiChatWeb.Live.ChatLive`**: Main chat interface
- **`AiChat.AI.Client`**: AI model integration
- **`AiChat.Accounts`**: User authentication and authorization
- **`AiChat.KnowledgeBases`**: Document processing and search
- **`AiChat.Organizations`**: Department and role management

## 🧪 Development

### **Running Tests**
```bash
# Run all tests
mix test

# Run with coverage
mix test --cover

# Run specific test file
mix test test/ai_chat/accounts_test.exs
```

### **Code Quality**
```bash
# Format code
mix format

# Run linter
mix credo

# Run pre-commit checks
mix precommit
```

### **Database Operations**
```bash
# Create migration
mix ecto.gen.migration add_new_feature

# Run migrations
mix ecto.migrate

# Rollback migration
mix ecto.rollback

# Reset database
mix ecto.reset
```

## 🤝 Contributing

We welcome contributions! Please follow these steps:

### **1. Setup Development Environment**
```bash
# Fork and clone the repository
git clone https://github.com/your-username/ai_chat.git
cd ai_chat

# Install dependencies
mix deps.get
cd assets && npm install && cd ..

# Setup database
mix ecto.create
mix ecto.migrate
mix run priv/repo/seeds.exs
```

### **2. Development Workflow**
```bash
# Create feature branch
git checkout -b feature/your-feature-name

# Make your changes
# ... code changes ...

# Run tests and checks
mix test
mix credo
mix format

# Commit changes
git commit -m "feat: add your feature description"

# Push to your fork
git push origin feature/your-feature-name
```

### **3. Pull Request Guidelines**
- **Title**: Use conventional commits format (`feat:`, `fix:`, `docs:`, etc.)
- **Description**: Clearly describe what the PR does and why
- **Tests**: Include tests for new functionality
- **Documentation**: Update README/docs if needed
- **Breaking Changes**: Clearly mark any breaking changes

### **4. Code Style**
- Follow Elixir community guidelines
- Use `mix format` for consistent formatting
- Write descriptive commit messages
- Add tests for new features
- Update documentation as needed

## 🐛 Troubleshooting

### **Common Issues**

#### Docker Build Fails
```bash
# Clean Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t ai-chat .
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
brew services list | grep postgresql

# Restart PostgreSQL
brew services restart postgresql

# Check database exists
mix ecto.create
```

#### Asset Compilation Issues
```bash
# Clean assets
rm -rf priv/static/assets
rm -rf _build

# Rebuild assets
mix assets.deploy
```

#### AI Model Connection Issues
- Verify API keys are correctly set
- Check network connectivity
- Ensure model endpoints are accessible
- Review AI API configuration in admin panel

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

### **Getting Help**
1. **Documentation**: Check this README and inline code documentation
2. **Issues**: Search existing [GitHub Issues](../../issues)
3. **Discussions**: Use [GitHub Discussions](../../discussions) for questions
4. **Community**: Join our community chat (link to be added)

### **Reporting Bugs**
When reporting bugs, please include:
- **Environment**: OS, Elixir version, Phoenix version
- **Steps to Reproduce**: Clear, numbered steps
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Logs**: Relevant error messages or logs

## 🔄 Changelog

### **v1.0.0** (Current)
- ✅ Multi-model AI chat support
- ✅ Role-based permission system
- ✅ Knowledge base integration
- ✅ Real-time streaming responses
- ✅ Docker deployment support
- ✅ Modern responsive UI
- ✅ Vector search capabilities

### **Upcoming Features**
- 🔄 Multi-language support
- 🔄 Advanced analytics dashboard
- 🔄 API rate limiting
- 🔄 Webhook integrations
- 🔄 Mobile app support

---

<div align="center">

**Built with ❤️ using Phoenix LiveView**

[⭐ Star this repo](../../stargazers) • [🐛 Report Bug](../../issues) • [💡 Request Feature](../../issues)

</div>