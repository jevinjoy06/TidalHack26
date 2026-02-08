// Central setup: registers all tools with the global registry.
// Call registerAllTools() at app startup (or before running the agent).
import 'tool_registry.dart';
import 'open_url_tool.dart';
import 'send_email_tool.dart';
import 'shopping_search_tool.dart';
import 'tavily_search_tool.dart';
import 'google_docs_tool.dart';
import 'read_calendar_tool.dart';
import 'notify_task_complete_tool.dart';

void registerAllTools() {
  final registry = ToolRegistry.global;

  registerOpenUrlTool(registry);
  registerSendEmailTool(registry);
  registerShoppingSearchTool(registry);
  registerTavilySearchTool(registry);
  registerCreateGoogleDocTool(registry);
  registerReadCalendarTool(registry);
  registerNotifyTaskCompleteTool(registry);
}
