// Central setup: registers all tools with the global registry.
// Call registerAllTools() at app startup (or before running the agent).
import 'tool_registry.dart';
import 'open_url_tool.dart';
import 'send_email_tool.dart';

void registerAllTools() {
  final registry = ToolRegistry.global;

  // Real implementations (no API keys needed)
  registerOpenUrlTool(registry);
  registerSendEmailTool(registry);

  // Stubs – return "Not implemented" until Phase 2 tools are built
  _registerStub(registry, 'shopping_search', 'Search for products on Google Shopping (SerpAPI). Returns titles, prices, links.', {
    'query': {'type': 'string', 'description': 'Search query e.g. "white tablecloth 6ft"'},
  });

  _registerStub(registry, 'tavily_search', 'Search the web for research, trends, factual info. AI-optimized.', {
    'query': {'type': 'string', 'description': 'Search query'},
  });

  _registerStub(registry, 'create_google_doc', 'Create a new Google Doc with the given title and content.', {
    'title': {'type': 'string', 'description': 'Document title'},
    'content': {'type': 'string', 'description': 'Document content (plain text or markdown)'},
  });

  _registerStub(registry, 'read_calendar', 'Read calendar events. Find dates like "next Thursday" or list events in a range.', {
    'query': {'type': 'string', 'description': 'e.g. "next Thursday", "events this week"'},
  });

  _registerStub(registry, 'notify_task_complete', 'Notify the user that a task is done. Show a message/summary.', {
    'summary': {'type': 'string', 'description': 'Brief summary of what was done'},
    'details': {'type': 'string', 'description': 'Optional additional details'},
  });
}

void _registerStub(ToolRegistry registry, String name, String description, Map<String, dynamic> properties) {
  final schema = {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': {
        'type': 'object',
        'properties': properties,
      },
    },
  };
  registry.register(name, schema, (_) async => 'Tool "$name" not yet implemented. API key or integration pending.');
}
