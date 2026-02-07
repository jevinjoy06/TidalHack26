import { LucideIcon } from "lucide-react";

interface SidebarNavItemProps {
  icon: LucideIcon;
  label: string;
  active?: boolean;
  onClick?: () => void;
}

export function SidebarNavItem({ icon: Icon, label, active = false, onClick }: SidebarNavItemProps) {
  return (
    <button
      onClick={onClick}
      className={`flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm transition-all focus:outline-none focus:ring-2 focus:ring-secondary/50 ${
        active
          ? "bg-accent/20 text-accent shadow-sm shadow-accent/20 border border-accent/30"
          : "text-foreground hover:bg-sidebar-accent hover:border hover:border-border"
      }`}
    >
      <Icon className="h-5 w-5" />
      <span>{label}</span>
    </button>
  );
}