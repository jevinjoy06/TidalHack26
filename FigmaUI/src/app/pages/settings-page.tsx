import { Zap, Lock, Link2, Box, FlaskConical, Moon } from "lucide-react";
import { SectionHeader } from "../components/section-header";
import { StatusCard } from "../components/status-card";
import { SettingsRow } from "../components/settings-row";
import { Switch } from "../components/ui/switch";

export function SettingsPage() {
  return (
    <div className="h-full overflow-auto">
      <div className="mx-auto max-w-4xl p-6">
        {/* Top Bar */}
        <div className="mb-8">
          <h1 className="text-3xl text-foreground">Settings</h1>
          <p className="text-sm text-muted-foreground mt-1">Configure your JARVIS instance</p>
        </div>

        {/* System Status Strip */}
        <div className="mb-6 rounded-lg border border-border/50 bg-card/30 px-4 py-2 backdrop-blur-sm">
          <div className="flex items-center justify-between text-xs font-mono">
            <div className="flex gap-6">
              <span className="text-muted-foreground">
                LATENCY: <span className="text-green-400">24ms</span>
              </span>
              <span className="text-muted-foreground">
                PROVIDER: <span className="text-secondary">ONLINE</span>
              </span>
              <span className="text-muted-foreground">
                MODEL: <span className="text-accent">GPT-4</span>
              </span>
            </div>
            <div className="h-2 w-2 rounded-full bg-green-400 animate-pulse" />
          </div>
        </div>

        <div className="space-y-8">
          {/* CONNECTION Section */}
          <div>
            <SectionHeader title="Connection" />
            <StatusCard
              icon={Zap}
              status="connected"
              title="API Connection"
              subtitle="API is ready and responding"
              lastChecked="Just now"
              onRefresh={() => console.log("Refresh")}
            />
          </div>

          {/* FEATHERLESS.AI API Section */}
          <div>
            <SectionHeader title="Featherless.ai API" />
            <div className="space-y-2 rounded-xl border border-border bg-card/40 p-4 backdrop-blur-sm">
              <SettingsRow
                icon={Lock}
                label="API Key"
                value="••••••••••••3a7f"
                onClick={() => console.log("Edit API Key")}
              />
              <SettingsRow
                icon={Link2}
                label="Base URL"
                value="https://api.featherless.ai/v1"
                onClick={() => console.log("Edit Base URL")}
              />
              <SettingsRow
                icon={Box}
                label="Model"
                value="gpt-4-turbo-preview"
                onClick={() => console.log("Select Model")}
              />
            </div>
          </div>

          {/* DEBUG Section */}
          <div>
            <SectionHeader title="Debug" badge="DEV MODE" />
            <div className="space-y-2 rounded-xl border border-border bg-card/40 p-4 backdrop-blur-sm">
              <SettingsRow
                icon={FlaskConical}
                label="Test Tool Calling (Step 1)"
                onClick={() => console.log("Test Tool Calling")}
              />
              <SettingsRow
                icon={FlaskConical}
                label="Test Orchestrator (Step 2)"
                onClick={() => console.log("Test Orchestrator")}
              />
              <SettingsRow
                icon={FlaskConical}
                label="Test Tool Registry (Step 3)"
                onClick={() => console.log("Test Tool Registry")}
              />
            </div>
          </div>

          {/* APPEARANCE Section */}
          <div>
            <SectionHeader title="Appearance" />
            <div className="space-y-2 rounded-xl border border-border bg-card/40 p-4 backdrop-blur-sm">
              <div className="flex items-center justify-between rounded-lg border border-border/50 bg-card/30 p-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-accent/30 bg-accent/20">
                    <Moon className="h-3.5 w-3.5 text-accent" />
                  </div>
                  <div>
                    <p className="text-sm text-foreground">Dark Mode</p>
                    <p className="text-xs text-muted-foreground mt-0.5">Enable dark theme</p>
                  </div>
                </div>
                <Switch checked={true} onCheckedChange={() => console.log("Toggle dark mode")} />
              </div>

              <div className="flex items-center justify-between rounded-lg border border-border/50 bg-card/30 p-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-accent/30 bg-accent/20">
                    <div className="h-3 w-3 rounded-full bg-accent" />
                  </div>
                  <div>
                    <p className="text-sm text-foreground">Accent Color</p>
                    <p className="text-xs text-muted-foreground mt-0.5">Crimson (default)</p>
                  </div>
                </div>
                <div className="flex gap-1">
                  <button className="h-6 w-6 rounded-full bg-accent border-2 border-white" />
                  <button className="h-6 w-6 rounded-full bg-blue-500 border-2 border-transparent opacity-50" />
                  <button className="h-6 w-6 rounded-full bg-purple-500 border-2 border-transparent opacity-50" />
                </div>
              </div>

              <div className="flex items-center justify-between rounded-lg border border-border/50 bg-card/30 p-4">
                <div className="flex items-center gap-3">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg border border-secondary/30 bg-secondary/20">
                    <div className="h-2 w-2 rounded-full bg-secondary" />
                  </div>
                  <div>
                    <p className="text-sm text-foreground">Reduce Motion</p>
                    <p className="text-xs text-muted-foreground mt-0.5">Minimize animations</p>
                  </div>
                </div>
                <Switch checked={false} onCheckedChange={() => console.log("Toggle reduce motion")} />
              </div>
            </div>
          </div>

          {/* Footer info */}
          <div className="rounded-lg border border-border/30 bg-card/20 p-4 text-center">
            <p className="text-xs font-mono text-muted-foreground">JARVIS v2.1.0 • Build 20260207</p>
            <p className="text-xs font-mono text-muted-foreground/50 mt-1">© 2026 Personal Project</p>
          </div>
        </div>
      </div>
    </div>
  );
}