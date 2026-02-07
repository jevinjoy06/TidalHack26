import { Plus, Filter, Sparkles } from "lucide-react";
import { Button } from "../components/ui/button";
import { SectionHeader } from "../components/section-header";
import { TaskItem } from "../components/task-item";

export function TasksPage() {
  const todayTasks = [
    { title: "Review Q1 performance metrics", subtitle: "Analytics team", dueTime: "10:00 AM", priority: "high" as const },
    { title: "Prepare presentation slides", subtitle: "Marketing meeting", dueTime: "2:00 PM", priority: "medium" as const },
    { title: "Update project documentation", subtitle: "Dev team", dueTime: "4:00 PM", priority: "low" as const },
    { title: "Schedule team sync", dueTime: "5:00 PM", priority: "medium" as const },
  ];

  const upcomingTasks = {
    Tomorrow: [
      { title: "Client demo preparation", subtitle: "Sales", priority: "high" as const },
      { title: "Code review for PR #342", subtitle: "Engineering", priority: "medium" as const },
    ],
    "This Week": [
      { title: "Budget planning session", priority: "medium" as const },
      { title: "Quarterly planning review", priority: "low" as const },
      { title: "Team retrospective", priority: "low" as const },
      { title: "Security audit follow-up", priority: "high" as const },
    ],
  };

  return (
    <div className="h-full overflow-auto">
      <div className="mx-auto max-w-6xl p-6">
        {/* Top Bar */}
        <div className="mb-8 flex items-center justify-between">
          <div>
            <h1 className="text-3xl text-foreground">Tasks</h1>
            <p className="text-sm text-muted-foreground mt-1">Manage and track your work</p>
          </div>
          <div className="flex items-center gap-2">
            <Button variant="outline" size="sm" className="gap-2">
              <Filter className="h-4 w-4" />
              Filter
            </Button>
            <Button className="gap-2 bg-accent text-accent-foreground hover:bg-accent/90 shadow-sm shadow-accent/20">
              <Plus className="h-4 w-4" />
              New task
            </Button>
          </div>
        </div>

        <div className="grid gap-6 lg:grid-cols-3">
          {/* Main Tasks Section */}
          <div className="lg:col-span-2 space-y-6">
            {/* Today Section */}
            <div className="rounded-xl border border-border bg-card/40 p-6 backdrop-blur-sm">
              <SectionHeader 
                title="Today" 
                badge="SYNC OK"
                action={
                  <div className="flex gap-2">
                    <span className="rounded-full bg-accent/20 px-3 py-1 text-xs text-accent border border-accent/30">
                      4 due today
                    </span>
                    <span className="rounded-full bg-green-500/20 px-3 py-1 text-xs text-green-400 border border-green-500/30">
                      2 completed
                    </span>
                  </div>
                }
              />
              
              <div className="space-y-2">
                {todayTasks.map((task, index) => (
                  <TaskItem key={index} {...task} />
                ))}
              </div>
            </div>

            {/* Upcoming Section */}
            <div className="rounded-xl border border-border bg-card/40 p-6 backdrop-blur-sm">
              <SectionHeader title="Upcoming" badge="LOCAL CACHE" />
              
              <div className="space-y-4">
                {Object.entries(upcomingTasks).map(([period, tasks]) => (
                  <div key={period}>
                    <h4 className="mb-2 text-xs text-muted-foreground uppercase tracking-wider">{period}</h4>
                    <div className="space-y-2">
                      {tasks.map((task, index) => (
                        <TaskItem key={index} {...task} />
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Quick Actions */}
            <div className="rounded-xl border border-border bg-card/40 p-6 backdrop-blur-sm">
              <SectionHeader title="Quick actions" />
              
              <div className="grid gap-2 sm:grid-cols-3">
                <Button variant="outline" className="justify-start gap-2 text-sm">
                  <Sparkles className="h-4 w-4" />
                  From conversation
                </Button>
                <Button variant="outline" className="justify-start gap-2 text-sm">
                  <Sparkles className="h-4 w-4" />
                  From email
                </Button>
                <Button variant="outline" className="justify-start gap-2 text-sm">
                  <Sparkles className="h-4 w-4" />
                  From notes
                </Button>
              </div>
            </div>
          </div>

          {/* AI Suggestions Panel */}
          <div className="lg:col-span-1">
            <div className="sticky top-6 rounded-xl border border-secondary/30 bg-card/40 p-6 backdrop-blur-sm">
              <div className="mb-4 flex items-center gap-2">
                <Sparkles className="h-4 w-4 text-secondary" />
                <h3 className="text-sm text-foreground">Suggested next actions</h3>
              </div>
              
              <div className="space-y-3">
                <div className="rounded-lg border border-border/50 bg-background/50 p-3">
                  <p className="text-xs text-foreground mb-1">Schedule follow-up for client demo</p>
                  <p className="text-xs text-muted-foreground">Based on your calendar</p>
                </div>
                <div className="rounded-lg border border-border/50 bg-background/50 p-3">
                  <p className="text-xs text-foreground mb-1">Review pending code reviews</p>
                  <p className="text-xs text-muted-foreground">3 PRs awaiting review</p>
                </div>
                <div className="rounded-lg border border-border/50 bg-background/50 p-3">
                  <p className="text-xs text-foreground mb-1">Update team on Q1 metrics</p>
                  <p className="text-xs text-muted-foreground">Deadline tomorrow</p>
                </div>
              </div>
              
              <Button variant="outline" className="mt-4 w-full gap-2 border-secondary/30 text-secondary hover:bg-secondary/10">
                Apply suggestions
              </Button>
              
              {/* System status */}
              <div className="mt-6 border-t border-border/50 pt-4">
                <p className="text-xs font-mono text-muted-foreground/50">LAST UPDATE: 2m ago</p>
                <p className="text-xs font-mono text-muted-foreground/50 mt-1">AI: ACTIVE</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
