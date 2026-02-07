interface SectionHeaderProps {
  title: string;
  badge?: string;
  action?: React.ReactNode;
}

export function SectionHeader({ title, badge, action }: SectionHeaderProps) {
  return (
    <div className="mb-4 flex items-center justify-between">
      <div className="flex items-center gap-3">
        <h2 className="text-lg text-foreground">{title}</h2>
        {badge && (
          <span className="rounded px-2 py-0.5 text-xs font-mono text-secondary/70 bg-secondary/10 border border-secondary/20">
            {badge}
          </span>
        )}
      </div>
      {action}
    </div>
  );
}
