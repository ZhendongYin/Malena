# Script to add broadcast_update calls to all CRUD operations

# Read the current file
content = File.read!("lib/ai_chat_web/controllers/admin_controller.ex")

# Define patterns to replace
replacements = [
  # Department operations
  {~r/(def update_department\(conn, %\{"id" => id, "department" => department_params\}\) do\s+department = Organizations\.get_department!\(id\)\s+case Organizations\.update_department\(department, department_params\) do\s+\{:ok, _department\} ->)/m,
   "\\1\n        broadcast_update(\"department\", \"updated\")"},

  {~r/(def delete_department\(conn, %\{"id" => id\}\) do\s+department = Organizations\.get_department!\(id\)\s+\{:ok, _department\} = Organizations\.delete_department\(department\))/m,
   "\\1\n    broadcast_update(\"department\", \"deleted\")"},

  # Role operations
  {~r/(def create_role\(conn, %\{"role" => role_params\}\) do\s+case Organizations\.create_role\(role_params\) do\s+\{:ok, _role\} ->)/m,
   "\\1\n        broadcast_update(\"role\", \"created\")"},

  {~r/(def update_role\(conn, %\{"id" => id, "role" => role_params\}\) do\s+role = Organizations\.get_role!\(id\)\s+case Organizations\.update_role\(role, role_params\) do\s+\{:ok, _role\} ->)/m,
   "\\1\n        broadcast_update(\"role\", \"updated\")"},

  {~r/(def delete_role\(conn, %\{"id" => id\}\) do\s+role = Organizations\.get_role!\(id\)\s+\{:ok, _role\} = Organizations\.delete_role\(role\))/m,
   "\\1\n    broadcast_update(\"role\", \"deleted\")"},

  # Prompt operations
  {~r/(def create_prompt\(conn, %\{"prompt" => prompt_params\}\) do\s+case Prompts\.create_prompt\(prompt_params\) do\s+\{:ok, _prompt\} ->)/m,
   "\\1\n        broadcast_update(\"prompt\", \"created\")"},

  {~r/(def update_prompt\(conn, %\{"id" => id, "prompt" => prompt_params\}\) do\s+prompt = Prompts\.get_prompt!\(id\)\s+case Prompts\.update_prompt\(prompt, prompt_params\) do\s+\{:ok, _prompt\} ->)/m,
   "\\1\n        broadcast_update(\"prompt\", \"updated\")"},

  {~r/(def delete_prompt\(conn, %\{"id" => id\}\) do\s+prompt = Prompts\.get_prompt!\(id\)\s+\{:ok, _prompt\} = Prompts\.delete_prompt\(prompt\))/m,
   "\\1\n    broadcast_update(\"prompt\", \"deleted\")"},

  # Knowledge Base operations
  {~r/(def create_knowledge_base\(conn, %\{"knowledge_base" => kb_params\}\) do\s+case KnowledgeBases\.create_knowledge_base\(kb_params\) do\s+\{:ok, _knowledge_base\} ->)/m,
   "\\1\n        broadcast_update(\"knowledge_base\", \"created\")"},

  {~r/(def update_knowledge_base\(conn, %\{"id" => id, "knowledge_base" => kb_params\}\) do\s+knowledge_base = KnowledgeBases\.get_knowledge_base!\(id\)\s+case KnowledgeBases\.update_knowledge_base\(knowledge_base, kb_params\) do\s+\{:ok, _knowledge_base\} ->)/m,
   "\\1\n        broadcast_update(\"knowledge_base\", \"updated\")"},

  {~r/(def delete_knowledge_base\(conn, %\{"id" => id\}\) do\s+knowledge_base = KnowledgeBases\.get_knowledge_base!\(id\)\s+\{:ok, _knowledge_base\} = KnowledgeBases\.delete_knowledge_base\(knowledge_base\))/m,
   "\\1\n    broadcast_update(\"knowledge_base\", \"deleted\")"},

  # AI API operations
  {~r/(def create_ai_api\(conn, %\{"ai_api" => api_params\}\) do\s+case AiApis\.create_ai_api\(api_params\) do\s+\{:ok, _ai_api\} ->)/m,
   "\\1\n        broadcast_update(\"ai_api\", \"created\")"},

  {~r/(def update_ai_api\(conn, %\{"id" => id, "ai_api" => api_params\}\) do\s+ai_api = AiApis\.get_ai_api!\(id\)\s+case AiApis\.update_ai_api\(ai_api, api_params\) do\s+\{:ok, _ai_api\} ->)/m,
   "\\1\n        broadcast_update(\"ai_api\", \"updated\")"}
]

# Apply replacements
updated_content = Enum.reduce(replacements, content, fn {pattern, replacement}, acc ->
  String.replace(acc, pattern, replacement)
end)

# Write the updated content
File.write!("lib/ai_chat_web/controllers/admin_controller.ex", updated_content)

IO.puts("Updated AdminController with broadcast_update calls")
