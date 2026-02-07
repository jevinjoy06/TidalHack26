import { useState } from "react";
import { Plus, MessageSquare, CheckSquare, Settings } from "lucide-react";
import { Button } from "./components/ui/button";
import { SidebarNavItem } from "./components/sidebar-nav-item";
import { SearchField } from "./components/search-field";
import { ChatItem } from "./components/chat-item";
import { HolographicWolf } from "./components/holographic-wolf";
import { ChatPage } from "./pages/chat-page";
import { TasksPage } from "./pages/tasks-page";
import { SettingsPage } from "./pages/settings-page";

type Page = "chat" | "tasks" | "settings";

export default function App() {
  const [currentPage, setCurrentPage] = useState<Page>("chat");

  const recentChats = [
    { title: "Weekly team sync notes", timestamp: "2 hours ago" },
    { title: "Project timeline planning", timestamp: "Yesterday" },
    { title: "Budget review Q1 2026", timestamp: "2 days ago" },
    { title: "Client feedback summary", timestamp: "3 days ago" },
    { title: "Marketing campaign ideas", timestamp: "1 week ago" },
    { title: "Technical documentation", timestamp: "1 week ago" },
  ];

  const renderPage = () => {
    switch (currentPage) {
      case "chat":
        return <ChatPage />;
      case "tasks":
        return <TasksPage />;
      case "settings":
        return <SettingsPage />;
      default:
        return <ChatPage />;
    }
  };

  return (
    <div className="flex h-screen bg-background overflow-hidden">
      {/* Left Sidebar */}
      <aside className="flex w-[280px] flex-shrink-0 flex-col border-r border-sidebar-border bg-sidebar p-4">
        {/* Logo/Brand with small wolf glyph */}
        <div className="mb-4 flex items-center gap-2 px-2">
          <HolographicWolf className="h-8 w-8" />
          <div>
            <h2 className="text-lg text-foreground tracking-wide">JARVIS</h2>
            <p className="text-xs font-mono text-muted-foreground">v2.1.0</p>
          </div>
        </div>

        {/* New Chat Button */}
        <Button 
          onClick={() => setCurrentPage("chat")}
          className="mb-4 w-full justify-start gap-2 bg-accent text-accent-foreground hover:bg-accent/90 shadow-sm shadow-accent/20"
        >
          <Plus className="h-4 w-4" />
          New Chat
        </Button>

        {/* Search Field - only show on chat page */}
        {currentPage === "chat" && (
          <div className="mb-6">
            <SearchField placeholder="Search conversations" />
          </div>
        )}

        {/* Recent Section - only show on chat page */}
        {currentPage === "chat" && (
          <div className="mb-4 flex-1 overflow-hidden">
            <h4 className="mb-2 px-1 text-xs text-muted-foreground uppercase tracking-wider">Recent</h4>
            <div className="space-y-1 overflow-y-auto pr-1" style={{ maxHeight: "calc(100vh - 400px)" }}>
              {recentChats.map((chat, index) => (
                <ChatItem
                  key={index}
                  title={chat.title}
                  timestamp={chat.timestamp}
                  active={index === 0}
                />
              ))}
            </div>
          </div>
        )}

        {/* Spacer when not on chat page */}
        {currentPage !== "chat" && <div className="flex-1" />}

        {/* Bottom Navigation */}
        <div className="space-y-1 border-t border-sidebar-border pt-4">
          <SidebarNavItem 
            icon={MessageSquare} 
            label="Chat" 
            active={currentPage === "chat"} 
            onClick={() => setCurrentPage("chat")}
          />
          <SidebarNavItem 
            icon={CheckSquare} 
            label="Tasks" 
            active={currentPage === "tasks"} 
            onClick={() => setCurrentPage("tasks")}
          />
          <SidebarNavItem 
            icon={Settings} 
            label="Settings" 
            active={currentPage === "settings"} 
            onClick={() => setCurrentPage("settings")}
          />
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex flex-1 flex-col overflow-hidden">
        {renderPage()}
      </main>
    </div>
  );
}
