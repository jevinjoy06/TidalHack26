import { Plus, MessageSquare, CheckSquare, Settings, User } from "lucide-react";
import { Button } from "./components/ui/button";
import { PromptCard } from "./components/prompt-card";
import { SidebarNavItem } from "./components/sidebar-nav-item";
import { SearchField } from "./components/search-field";
import { ChatItem } from "./components/chat-item";
import { ChatInputBar } from "./components/chat-input-bar";
import { HudBackground } from "./components/hud-background";
import { HolographicOwl } from "./components/holographic-owl";
import { HolographicWolf } from "./components/holographic-wolf";

export default function App() {
  const recentChats = [
    { title: "Weekly team sync notes", timestamp: "2 hours ago" },
    { title: "Project timeline planning", timestamp: "Yesterday" },
    { title: "Budget review Q1 2026", timestamp: "2 days ago" },
    { title: "Client feedback summary", timestamp: "3 days ago" },
    { title: "Marketing campaign ideas", timestamp: "1 week ago" },
    { title: "Technical documentation", timestamp: "1 week ago" },
  ];

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
        <Button className="mb-4 w-full justify-start gap-2 bg-accent text-accent-foreground hover:bg-accent/90 shadow-sm shadow-accent/20">
          <Plus className="h-4 w-4" />
          New Chat
        </Button>

        {/* Search Field */}
        <div className="mb-6">
          <SearchField placeholder="Search conversations" />
        </div>

        {/* Recent Section */}
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

        {/* Bottom Navigation */}
        <div className="space-y-1 border-t border-sidebar-border pt-4">
          <SidebarNavItem icon={MessageSquare} label="Chat" active={true} />
          <SidebarNavItem icon={CheckSquare} label="Tasks" />
          <SidebarNavItem icon={Settings} label="Settings" />
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="relative flex flex-1 flex-col overflow-hidden">
        {/* HUD Background */}
        <HudBackground />

        {/* Top Bar */}
        <div className="relative z-10 flex items-center justify-end gap-3 border-b border-border/50 bg-background/80 px-6 py-3 backdrop-blur-sm">
    {/* <Button
            variant="outline"
            className="gap-2 border-secondary/30 bg-card/40 text-secondary hover:bg-card/60 hover:border-secondary/50 hover:text-secondary shadow-sm"
          >
            Voice Mode
          </Button> */}
          <div className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-accent to-secondary shadow-sm shadow-accent/30">
            <User className="h-4 w-4 text-white" />
          </div>
        </div>

        {/* Scrollable Content */}
        <div className="relative z-10 flex flex-1 items-center justify-center overflow-auto px-6 py-12">
          <div className="w-full max-w-6xl">
            {/* Large Holographic Owl - positioned to the right */}
            <HolographicOwl className="absolute right-12 top-1/2 h-64 w-64 -translate-y-1/2 opacity-40" />

            {/* Main Hero Section */}
            <div className="relative flex flex-col items-center text-center">
              {/* Title with glow effect */}
              <div className="mb-3">
                <h1 className="text-5xl bg-gradient-to-r from-foreground via-accent to-secondary bg-clip-text text-transparent">
                  Howdy, I am JARVIS
                </h1>
                <div className="mx-auto mt-2 h-px w-64 bg-gradient-to-r from-transparent via-accent/50 to-transparent" />
              </div>

              <p className="mb-12 max-w-2xl text-lg text-muted-foreground">
                Your personal command center for chat, tasks, and automation.
              </p>

              {/* Quick-start Prompt Cards - 2x3 grid */}
              <div className="relative z-20 mb-12 grid w-full max-w-4xl grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <PromptCard text="Summarize my latest messages" />
                <PromptCard text="Draft a reply in a friendly tone" />
                <PromptCard text="Turn this into tasks" />
                <PromptCard text="Plan my day" />
                <PromptCard text="Extract action items" />
                <PromptCard text="Find key dates" />
              </div>

              {/* CTAs */}
              <div className="mb-16 flex flex-col items-center gap-3 sm:flex-row">
                {/* <Button className="gap-2 bg-accent text-accent-foreground hover:bg-accent/90 shadow-lg shadow-accent/30 px-8 py-6 text-base">
                  <Plus className="h-5 w-5" />
                  Start a new chat
                </Button> */}
                {/* <Button 
                  variant="outline" 
                  className="border-secondary/30 bg-card/40 text-secondary hover:bg-card/60 hover:border-secondary/50 px-8 py-6 text-base"
                >
                  Voice Mode
                </Button> */}
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Input Bar */}
        <div className="relative z-10 border-t border-border/50 bg-background/80 px-6 py-4 backdrop-blur-sm">
          <ChatInputBar />
        </div>
      </main>
    </div>
  );
}
