export function HolographicOwl({ className = "" }: { className?: string }) {
  return (
    <div className={`pointer-events-none ${className}`}>
      <svg
        viewBox="0 0 200 200"
        fill="none"
        xmlns="http://www.w3.org/2000/svg"
        className="h-full w-full"
      >
        {/* Outer glow */}
        <circle cx="100" cy="100" r="80" fill="#0ea5e9" opacity="0.05" />
        
        {/* Owl wireframe */}
        {/* Head outline */}
        <ellipse cx="100" cy="85" rx="45" ry="50" stroke="#0ea5e9" strokeWidth="1" opacity="0.8" />
        
        {/* Ear tufts */}
        <path d="M 70 50 L 75 35 L 80 50" stroke="#0ea5e9" strokeWidth="1" fill="none" opacity="0.7" />
        <path d="M 130 50 L 125 35 L 120 50" stroke="#0ea5e9" strokeWidth="1" fill="none" opacity="0.7" />
        
        {/* Eyes - large circles */}
        <circle cx="85" cy="80" r="12" stroke="#0ea5e9" strokeWidth="1.5" opacity="0.9" />
        <circle cx="115" cy="80" r="12" stroke="#0ea5e9" strokeWidth="1.5" opacity="0.9" />
        
        {/* Pupils */}
        <circle cx="85" cy="80" r="5" fill="#dc2626" opacity="0.8">
          <animate attributeName="opacity" values="0.8;1;0.8" dur="3s" repeatCount="indefinite" />
        </circle>
        <circle cx="115" cy="80" r="5" fill="#dc2626" opacity="0.8">
          <animate attributeName="opacity" values="0.8;1;0.8" dur="3s" repeatCount="indefinite" />
        </circle>
        
        {/* Beak */}
        <path d="M 100 90 L 95 100 L 100 105 L 105 100 Z" stroke="#0ea5e9" strokeWidth="1" fill="none" opacity="0.7" />
        
        {/* Body */}
        <ellipse cx="100" cy="145" rx="35" ry="40" stroke="#0ea5e9" strokeWidth="1" opacity="0.6" />
        
        {/* Wings */}
        <path d="M 65 130 Q 45 145 50 165" stroke="#0ea5e9" strokeWidth="1" fill="none" opacity="0.5" />
        <path d="M 135 130 Q 155 145 150 165" stroke="#0ea5e9" strokeWidth="1" fill="none" opacity="0.5" />
        
        {/* Feather details */}
        <path d="M 100 120 L 100 135" stroke="#0ea5e9" strokeWidth="0.5" opacity="0.4" />
        <path d="M 90 125 L 90 140" stroke="#0ea5e9" strokeWidth="0.5" opacity="0.4" />
        <path d="M 110 125 L 110 140" stroke="#0ea5e9" strokeWidth="0.5" opacity="0.4" />
        
        {/* Tech overlay lines */}
        <path d="M 60 85 L 140 85" stroke="#dc2626" strokeWidth="0.3" opacity="0.3" strokeDasharray="2,2" />
        <path d="M 75 110 L 125 110" stroke="#dc2626" strokeWidth="0.3" opacity="0.3" strokeDasharray="2,2" />
      </svg>
    </div>
  );
}
