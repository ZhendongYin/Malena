# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AiChat.Repo.insert!(%AiChat.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias AiChat.{Accounts, Organizations, ApiKeys, Prompts, AiApis}

# Create departments
{:ok, hr_dept} = Organizations.create_department(%{
  name: "Human Resources",
  description: "Human Resources Department",
  api_access_enabled: true
})

{:ok, it_dept} = Organizations.create_department(%{
  name: "Information Technology",
  description: "IT Department",
  api_access_enabled: true
})

{:ok, finance_dept} = Organizations.create_department(%{
  name: "Finance",
  description: "Finance Department",
  api_access_enabled: false
})

# Create roles
{:ok, super_admin_role} = Organizations.create_role(%{
  name: "Super Admin",
  department_id: hr_dept.id,
  permissions: %{
    "super_admin" => true,
    "manage_users" => true,
    "manage_prompts" => true,
    "manage_knowledge_bases" => true,
    "manage_ai_apis" => true,
    "access_chat" => true
  },
  api_permissions: %{
    "chat" => true,
    "knowledge_base" => true,
    "admin" => true
  }
})

{:ok, hr_manager_role} = Organizations.create_role(%{
  name: "HR Manager",
  department_id: hr_dept.id,
  permissions: %{
    "department_admin" => true,
    "manage_users" => true,
    "manage_prompts" => true,
    "manage_knowledge_bases" => true,
    "access_chat" => true
  },
  api_permissions: %{
    "chat" => true,
    "knowledge_base" => true
  }
})

{:ok, hr_employee_role} = Organizations.create_role(%{
  name: "HR Employee",
  department_id: hr_dept.id,
  permissions: %{
    "access_chat" => true
  },
  api_permissions: %{
    "chat" => true
  }
})

{:ok, it_manager_role} = Organizations.create_role(%{
  name: "IT Manager",
  department_id: it_dept.id,
  permissions: %{
    "department_admin" => true,
    "manage_users" => true,
    "manage_prompts" => true,
    "manage_knowledge_bases" => true,
    "manage_ai_apis" => true,
    "access_chat" => true
  },
  api_permissions: %{
    "chat" => true,
    "knowledge_base" => true,
    "admin" => true
  }
})

# Create users
{:ok, admin_user} = Accounts.create_user(%{
  name: "Super Admin",
  email: "admin@aichat.com",
  password: "password123",
  department_id: hr_dept.id,
  role_id: super_admin_role.id
})

{:ok, hr_manager} = Accounts.create_user(%{
  name: "HR Manager",
  email: "hr.manager@aichat.com",
  password: "password123",
  department_id: hr_dept.id,
  role_id: hr_manager_role.id
})

{:ok, hr_employee} = Accounts.create_user(%{
  name: "HR Employee",
  email: "hr.employee@aichat.com",
  password: "password123",
  department_id: hr_dept.id,
  role_id: hr_employee_role.id
})

{:ok, it_manager} = Accounts.create_user(%{
  name: "IT Manager",
  email: "it.manager@aichat.com",
  password: "password123",
  department_id: it_dept.id,
  role_id: it_manager_role.id
})

# Create API keys for testing
{:ok, admin_api_key, admin_key} = ApiKeys.create_api_key(%{
  name: "Admin API Key",
  user_id: admin_user.id,
  permissions: %{
    "chat" => true,
    "knowledge_base" => true,
    "admin" => true
  }
})

{:ok, hr_api_key, hr_key} = ApiKeys.create_api_key(%{
  name: "HR API Key",
  user_id: hr_manager.id,
  permissions: %{
    "chat" => true,
    "knowledge_base" => true
  }
})

# Create sample prompts
{:ok, hr_prompt} = Prompts.create_prompt(%{
  title: "HR Assistant",
  content: "You are a helpful HR assistant. You have access to company policies and procedures. Please provide accurate and helpful information to employees. Always be professional and courteous.",
  variables: %{
    "user_name" => "Employee Name",
    "department_name" => "Department"
  },
  department_id: hr_dept.id,
  role_id: hr_employee_role.id,
  api_accessible: true
})

{:ok, it_prompt} = Prompts.create_prompt(%{
  title: "IT Support Assistant",
  content: "You are an IT support assistant. You help employees with technical issues and provide guidance on IT policies and procedures. Be clear and concise in your explanations.",
  variables: %{
    "user_name" => "Employee Name",
    "issue_type" => "Issue Type"
  },
  department_id: it_dept.id,
  role_id: it_manager_role.id,
  api_accessible: true
})

# Create sample AI API configurations
{:ok, openai_api} = AiApis.create_ai_api(%{
  name: "OpenAI GPT-4",
  provider: "openai",
  api_key: "sk-test-key",
  model_name: "gpt-4",
  department_id: hr_dept.id,
  role_id: hr_manager_role.id,
  max_tokens: 4000,
  temperature: 0.7
})

{:ok, claude_api} = AiApis.create_ai_api(%{
  name: "Claude 3",
  provider: "claude",
  api_key: "claude-test-key",
  model_name: "claude-3-sonnet-20240229",
  department_id: it_dept.id,
  role_id: it_manager_role.id,
  max_tokens: 4000,
  temperature: 0.7
})

IO.puts("""
Seeds created successfully!

Users:
- Super Admin: admin@aichat.com / password123
- HR Manager: hr.manager@aichat.com / password123
- HR Employee: hr.employee@aichat.com / password123
- IT Manager: it.manager@aichat.com / password123

API Keys:
- Admin API Key: #{admin_key}
- HR API Key: #{hr_key}
""")
