import { useState } from 'react';
import { Lock, Unlock, ChevronDown, Check, X, FileCheck2 } from 'lucide-react';

export default function App() {
  // --- STATE VARIABLES (watched vars) ---
  const [isLocked, setIsLocked] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [task, setTask] = useState('Ready to update');
  const [progress, setProgress] = useState(0);

  // 'Dictionary' holding all data associated with each branch - hard defined for now because no backend to pull real settings
  const [branches, setBranches] = useState([
    { id: 'stable', name: 'Discord Stable', path: 'C:/Users/Alex/AppData/Local/Discord', enabled: true },
    { id: 'ptb', name: 'Discord PTB', path: 'C:/Users/Alex/AppData/Local/DiscordPTB', enabled: false },
    { id: 'canary', name: 'Discord Canary', path: 'C:/Users/Alex/AppData/Local/DiscordCanary', enabled: false },
  ]);

  // Tracks currently selected branch
  const [activeBranchId, setActiveBranchId] = useState('stable');

  // Helper to find full object - activeBranchId is just a string, this helper takes that string and returns the object itself (with the name, path, enabled status
  const activeBranch = branches.find(b => b.id === activeBranchId);

  // --- LOGIC FUNCTIONS ---

  // Flips the lock state
  const toggleLock = () => {
    setIsLocked(!isLocked);
    if (!isLocked) {
      setTask('Application Locked. Interaction disabled.');
    } else {
      setTask('Ready to update');
    }
  };

  // Select a branch from the dropdown menu - updates active id then closes dropdown after click CHORE: make it expire if cursor exit zone?
  const selectBranch = (branchId) => {
    setActiveBranchId(branchId);
    setIsDropdownOpen(false);
  };

  // Updates data of that branch that was selected
  const toggleActiveBranch = () => {
    // 1. Update the state visually
    setBranches(branches.map(branch => 
      branch.id === activeBranchId 
        ? { ...branch, enabled: !branch.enabled } 
        : branch
    ));

    // 2. Trigger the backend (not working on this yet) (Node/Python/Rust)
    console.log(`Backend Trigger: Toggled ${activeBranch.name} to ${!activeBranch.enabled}`);
  };

  // --- UI RENDER ---
  return (
    // Main Window Container
    <div className="w-[600px] bg-zinc-300 border-2 border-black shadow-2xl relative select-none">
      
      {/* 1. TOP LABEL (The angular visual) */}
      <div className="clip-header bg-zinc-200 border-b-2 border-black h-14 w-[85%] flex items-center px-3 gap-3 absolute top-0 left-0 z-10">
        
        {/* Lock Icon */}
        <button 
          onClick={toggleLock}
          className="bg-zinc-800 p-1.5 border-2 border-black hover:bg-zinc-700 active:bg-zinc-900 cursor-pointer"
        >
          {isLocked ? <Lock size={20} color="white" /> : <Unlock size={20} color="white" />}
        </button>

        {/* Title */}
        <div className="bg-zinc-800 text-zinc-100 px-4 py-1 border-2 border-black font-bold tracking-wide">
          BetterDiscord Auto-Updater
        </div>
      </div>

      {/* Spacer to push content down below the absolute-positioned header */}
      <div className="h-14"></div>

      {/* 2. MAIN CONTENT AREA */}
      {/* If isLocked is true, apply 'pointer-events-none' to ignore clicks, and 'opacity-60' to darken it */}
      <div className={`p-6 flex flex-col gap-8 transition-opacity duration-200 ${isLocked ? 'opacity-60 pointer-events-none' : 'opacity-100'}`}>
        
        {/* Row: Discord Info Box & Toggle */}
        <div className="flex items-center justify-between gap-6">
          
          {/* Center-Left: Discord Info Box */}
          <div className="bg-zinc-400 border-2 border-black p-3 flex-1 flex gap-4 relative">
            
            {/* Discord Icon & Dropdown Arrow */}
            <div 
              className="bg-zinc-300 border-2 border-black w-20 h-20 flex items-center justify-center relative cursor-pointer hover:bg-zinc-200"
              onClick={() => setIsDropdownOpen(!isDropdownOpen)}
            >
              {/* Fake Discord Icon using standard shapes for now */}
              <div className="w-10 h-8 bg-zinc-800 rounded-full flex justify-center items-center gap-2">
                 <div className="w-2 h-2 bg-white rounded-full"></div>
                 <div className="w-2 h-2 bg-white rounded-full"></div>
              </div>
              <div className="absolute bottom-1 right-1 bg-zinc-800 rounded-sm">
                <ChevronDown size={14} color="white" />
              </div>
            </div>

            {/* Dropdown Menu (Only visible if isDropdownOpen is true) */}
            {isDropdownOpen && (
              <div className="absolute top-24 left-3 bg-zinc-800 border-2 border-black shadow-xl z-20 flex flex-col">
                {branches.map(branch => (
                  <button 
                    key={branch.id}
                    onClick={() => selectBranch(branch.id)}
                    className="text-white px-4 py-2 text-left hover:bg-zinc-700 border-b border-zinc-600 last:border-0"
                  >
                    {branch.name}
                  </button>
                ))}
              </div>
            )}

            {/* Branch Details */}
            <div className="flex flex-col gap-2 flex-1 justify-center">
              <div className="bg-zinc-800 text-white px-3 py-1 border-2 border-black font-semibold">
                Discord - [{activeBranch.name.split(' ')[1]}]
              </div>
              <div className="bg-zinc-800 text-white px-3 py-1 border-2 border-black text-sm truncate font-mono">
                {activeBranch.path}
              </div>
            </div>
          </div>

          {/* Toggle Checkbox */}
          <div className="flex flex-col items-center gap-1">
            <span className="font-bold text-zinc-800">Toggle</span>
            <button 
              onClick={toggleActiveBranch}
              className="w-16 h-16 bg-zinc-800 border-2 border-black flex items-center justify-center hover:bg-zinc-700 active:bg-zinc-900 transition-colors"
            >
              {activeBranch.enabled ? (
                <Check size={40} color="#22c55e" strokeWidth={3} /> // Green Check
              ) : (
                <X size={40} color="#ef4444" strokeWidth={3} /> // Red X
              )}
            </button>
          </div>
        </div>

        {/* 3. BOTTOM AREA */}
        <div className="flex flex-col gap-2 mt-4">
          
          <div className="flex items-center gap-2 text-zinc-800 font-bold mb-2">
             <FileCheck2 size={20} /> Valid Settings File
          </div>

          <div className="font-mono text-sm font-bold text-zinc-800">
            Task: {task}
          </div>
          
          {/* Loading Bar */}
          <div className="w-full h-6 bg-zinc-800 border-2 border-black relative overflow-hidden">
            <div 
              className="h-full bg-blue-500 transition-all duration-300 ease-out"
              style={{ width: `${progress}%` }}
            ></div>
            {/* Striped overlay effect */}
            <div className="absolute inset-0 opacity-20" style={{ backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 10px, #000 10px, #000 20px)' }}></div>
          </div>
          
          {/* Dummy controls to test the progress bar visually */}
          <div className="flex gap-2 text-xs">
            <button className="underline pointer-events-auto" onClick={() => setProgress(Math.min(progress + 10, 100))}>Simulate Progress +</button>
            <button className="underline pointer-events-auto" onClick={() => setProgress(0)}>Reset</button>
          </div>
        </div>

      </div>
    </div>
  );
}