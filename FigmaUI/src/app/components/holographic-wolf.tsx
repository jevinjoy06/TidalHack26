export function HolographicWolf({ className = "" }: { className?: string }) {
  return (
    <div className={`pointer-events-none ${className}`}>
      <svg
        viewBox="0 0 80 80"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="h-full w-full"
      >
        {/* Small glow */}
        <circle cx="40" cy="40" r="35" fill="#dc2626" opacity="0.05" />
        
        {/* Wolf head silhouette - wireframe */}
        {/* Ears */}
        <path d="M 25 20 L 30 10 L 32 20" stroke="#dc2626" strokeWidth="0.8" fill="none" opacity="0.7" />
        <path d="M 55 20 L 50 10 L 48 20" stroke="#dc2626" strokeWidth="0.8" fill="none" opacity="0.7" />
        
        {/* Head */}
        <ellipse cx="40" cy="35" rx="15" ry="18" stroke="#dc2626" strokeWidth="0.8" opacity="0.8" />
        
        {/* Snout */}
        <path d="M 40 45 Q 35 50 35 55 L 40 57 L 45 55 Q 45 50 40 45" stroke="#dc2626" strokeWidth="0.8" fill="none" opacity="0.7" />
        
        {/* Eyes */}
        <circle cx="35" cy="32" r="2" fill="#0ea5e9" opacity="0.9" />
        <circle cx="45" cy="32" r="2" fill="#0ea5e9" opacity="0.9" />
        
        {/* Neck/body hint */}
        <path d="M 30 50 L 28 65" stroke="#dc2626" strokeWidth="0.6" opacity="0.5" />
        <path d="M 50 50 L 52 65" stroke="#dc2626" strokeWidth="0.6" opacity="0.5" />
        
        {/* Tech scan lines */}
        <line x1="25" y1="35" x2="55" y2="35" stroke="#0ea5e9" strokeWidth="0.3" opacity="0.3" strokeDasharray="1,1" />
      </svg>
    </div>
  );
}
