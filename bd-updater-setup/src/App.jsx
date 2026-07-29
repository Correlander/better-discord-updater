import { useState } from 'react';
import { Lock, Unlock, Check, X, Edit2 } from 'lucide-react';

// Official Discord SVG Component (inherits color via fill="currentColor")
function DiscordIcon({ size = 20, className = "" }) {
  return (
    <svg 
      width={size} 
      height={size} 
      viewBox="0 0 127.14 96.36" 
      fill="currentColor" 
      className={className}
    >
      <path d="M107.7,8.07A105.15,105.15,0,0,0,81.47,0a72.06,72.06,0,0,0-3.36,6.83A97.68,97.68,0,0,0,49,6.83,72.37,72.37,0,0,0,45.64,0,105.89,105.89,0,0,0,19.39,8.09C2.79,32.65-1.71,56.6.54,80.21h0A105.73,105.73,0,0,0,32.71,96.36,77.7,77.7,0,0,0,39.6,85.25a68.42,68.42,0,0,1-10.85-5.18c.91-.66,1.8-1.34,2.66-2a75.57,75.57,0,0,0,64.32,0c.87.71,1.76,1.39,2.66,2a68.68,68.68,0,0,1-10.87,5.19,77,77,0,0,0,6.89,11.1,105.25,105.25,0,0,0,32.19-16.15c2.65-27.28-4.51-51.2-19.12-72.15ZM42.45,65.69C36.18,65.69,31,60,31,53s5.18-12.72,11.45-12.72S53.9,46,53.88,53,48.71,65.69,42.45,65.69Zm42.24,0C78.41,65.69,73.25,60,73.25,53s5.18-12.72,11.44-12.72S96.13,46,96.13,53,90.95,65.69,84.69,65.69Z"/>
    </svg>
  );
}

export default function App() {
  // --- STATE ---
  const [isLocked, setIsLocked] = useState(false);
  const [isDropdownOpen, setIsDropdownOpen] = useState(false);
  const [task, setTask] = useState(''); // Default is empty
  const [progress, setProgress] = useState(0);

  // Path editing state
  const [editingBranchId, setEditingBranchId] = useState(null);
  const [tempPath, setTempPath] = useState('');

  // Define available branches with custom color themes
  const [branches, setBranches] = useState([
    { id: 'stable', name: 'Discord Stable', path: 'C:/Users/Alex/AppData/Local/Discord', enabled: true, color: 'text-indigo-400' },
    { id: 'ptb', name: 'Discord PTB', path: 'C:/Users/Alex/AppData/Local/DiscordPTB', enabled: false, color: 'text-purple-400' },
    { id: 'canary', name: 'Discord Canary', path: 'C:/Users/Alex/AppData/Local/DiscordCanary', enabled: false, color: 'text-amber-400' },
  ]);

  const [activeBranchId, setActiveBranchId] = useState('stable');
  const activeBranch = branches.find(b => b.id === activeBranchId);

  // --- BACKEND PLACEHOLDER (Future Tauri IPC) ---
  const invokeBackend = async (command, payload) => {
    console.log(`[Tauri Invoke] Command: "${command}"`, payload);
    // When Tauri is set up, this will be: 
    // return await window.__TAURI__.invoke(command, payload);
    return new Promise(resolve => setTimeout(resolve, 500));
  };

  // --- DEDICATED LOADING & TASK HANDLER ---
  const executeTaskWithProgress = async (steps) => {
    setIsLocked(true);
    try {
      for (const step of steps) {
        setTask(step.message);
        setProgress(step.progress);
        if (step.action) {
          await step.action();
        }
      }
      await new Promise(r => setTimeout(r, 500)); // Brief pause at 100% completion
    } catch (err) {
      console.error(err);
      setTask('Error executing background task.');
      await new Promise(r => setTimeout(r, 1500));
    } finally {
      setIsLocked(false);
      setProgress(0);
      setTask(''); // Clears text back to empty when finished
    }
  };

  // --- LOGIC FUNCTIONS ---
  const selectBranch = (branchId) => {
    if (isLocked) return;
    setActiveBranchId(branchId);
    setIsDropdownOpen(false);
    setEditingBranchId(null);
  };

  // Trigger Branch Toggle via Task Runner
  const handleToggleActiveBranch = async () => {
    if (isLocked) return;
    const targetState = !activeBranch.enabled;

    await executeTaskWithProgress([
      {
        message: `Initializing config for ${activeBranch.name}...`,
        progress: 15,
        action: () => invokeBackend('pre_flight_check', { branchId: activeBranchId })
      },
      {
        message: `Writing settings to ${activeBranch.path}...`,
        progress: 50,
        action: () => invokeBackend('update_betterdiscord_config', { 
          branchId: activeBranchId, 
          enabled: targetState,
          path: activeBranch.path 
        })
      },
      {
        message: 'Applying updates and restarting watcher...',
        progress: 85,
        action: () => invokeBackend('restart_discord_service', {})
      },
      {
        message: `Successfully updated ${activeBranch.name}!`,
        progress: 100,
        action: async () => {
          setBranches(branches.map(branch => 
            branch.id === activeBranchId 
              ? { ...branch, enabled: targetState } 
              : branch
          ));
        }
      }
    ]);
  };

  // Path Editing Handlers
  const startEditingPath = (branch) => {
    if (isLocked) return;
    setEditingBranchId(branch.id);
    setTempPath(branch.path);
    setIsDropdownOpen(false);
  };

  const savePath = async (branchId) => {
    if (isLocked) return;

    await executeTaskWithProgress([
      {
        message: 'Saving custom installation path...',
        progress: 50,
        action: async () => {
          setBranches(branches.map(b => 
            b.id === branchId ? { ...b, path: tempPath } : b
          ));
          setEditingBranchId(null);
          await invokeBackend('save_custom_path', { branchId, path: tempPath });
        }
      },
      {
        message: 'Path successfully updated.',
        progress: 100,
      }
    ]);
  };

  return (
    // Main Window Container (Dark Utility Theme)
    <div className="w-[600px] bg-zinc-900 text-zinc-100 border-2 border-zinc-700 shadow-2xl relative select-none">
      
      {/* 1. TOP LABEL (Angular Header) */}
      <div className="clip-header bg-zinc-800 border-b-2 border-zinc-700 h-14 w-[85%] flex items-center px-3 gap-3 absolute top-0 left-0 z-10">
        
        {/* Read-Only Lock Indicator */}
        <div 
          className="bg-zinc-700 p-1.5 border-2 border-zinc-600 flex items-center justify-center"
          title={isLocked ? "Application Locked (Task in progress)" : "Application Unlocked"}
        >
          {isLocked ? <Lock size={20} color="#f87171" /> : <Unlock size={20} color="#4ade80" />}
        </div>

        {/* Title */}
        <div className="bg-zinc-900 text-zinc-100 px-4 py-1 border-2 border-zinc-700 font-bold tracking-wide text-sm">
          BetterDiscord Auto-Updater
        </div>
      </div>

      {/* Spacer for absolute header */}
      <div className="h-14"></div>

      {/* 2. MAIN CONTENT AREA */}
      <div className={`p-6 flex flex-col gap-6 transition-opacity duration-200 ${isLocked ? 'opacity-50 pointer-events-none' : 'opacity-100'}`}>
        
        {/* Row: Discord Info Box & Toggle */}
        <div className="flex items-center justify-between gap-4">
          
          {/* Center-Left: Discord Info Box */}
          <div className="bg-zinc-800 border-2 border-zinc-700 p-3 flex-1 flex gap-4 relative min-w-0">
            
            {/* Discord Icon Box & Dropdown Container */}
            <div className="relative shrink-0">
              <div 
                className="bg-zinc-900 border-2 border-zinc-700 w-20 h-20 flex items-center justify-center relative cursor-pointer hover:bg-zinc-950 transition-colors z-10"
                onClick={() => setIsDropdownOpen(!isDropdownOpen)}
              >
                <DiscordIcon size={40} className={activeBranch.color} />
              </div>

              {/* Dropdown Menu Container with Seamless Hover Bridge */}
              {isDropdownOpen && (
                <div 
                  className="absolute top-0 left-0 pt-20 z-20 w-64"
                  onMouseLeave={() => setIsDropdownOpen(false)}
                >
                  <div className="bg-zinc-800 border-2 border-zinc-700 shadow-2xl flex flex-col mt-2">
                    {branches.map(branch => (
                      <button 
                        key={branch.id}
                        onClick={() => selectBranch(branch.id)}
                        className="text-zinc-200 px-3 py-2.5 text-left hover:bg-zinc-700 border-b border-zinc-700 last:border-0 flex items-center gap-3 transition-colors cursor-pointer"
                      >
                        <DiscordIcon size={18} className={`${branch.color} shrink-0`} />
                        <span className="truncate text-sm font-medium">{branch.name}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Branch Details & Inline Path Editor */}
            <div className="flex flex-col gap-2 flex-1 min-w-0 justify-center">
              
              {/* Active Branch Tag */}
              <div className="bg-zinc-900 text-zinc-200 px-3 py-1 border-2 border-zinc-700 font-semibold text-xs flex items-center justify-between">
                <span>Discord - [{activeBranch.name.split(' ')[1]}]</span>
                <span className="text-[10px] text-zinc-400 font-normal">Click icon to switch</span>
              </div>

              {/* Path Display / Inline Editor */}
              {editingBranchId === activeBranch.id ? (
                <div className="flex items-center gap-1">
                  <input
                    type="text"
                    value={tempPath}
                    onChange={(e) => setTempPath(e.target.value)}
                    onKeyDown={(e) => {
                      if (e.key === 'Enter') savePath(activeBranch.id);
                      if (e.key === 'Escape') setEditingBranchId(null);
                    }}
                    autoFocus
                    className="w-full bg-zinc-950 text-indigo-300 px-2 py-1 border-2 border-indigo-500 font-mono text-xs outline-none"
                  />
                  <button 
                    onClick={() => savePath(activeBranch.id)} 
                    className="bg-zinc-700 px-2 py-1 text-xs border border-zinc-600 hover:bg-zinc-600 cursor-pointer"
                  >
                    Save
                  </button>
                </div>
              ) : (
                <div 
                  onClick={() => startEditingPath(activeBranch)}
                  className="bg-zinc-900 text-zinc-300 px-3 py-1 border-2 border-zinc-700 text-xs truncate font-mono flex items-center justify-between cursor-pointer hover:border-zinc-500 transition-colors group"
                  title="Click to edit path"
                >
                  <span className="truncate">{activeBranch.path}</span>
                  <Edit2 size={12} className="text-zinc-500 group-hover:text-zinc-300 shrink-0 ml-1" />
                </div>
              )}

            </div>
          </div>

          {/* Center-Right: Toggle Action Button */}
          <div className="flex flex-col items-center gap-1 shrink-0">
            <span className="font-bold text-xs text-zinc-300 uppercase tracking-wider">Toggle</span>
            <button 
              onClick={handleToggleActiveBranch}
              disabled={isLocked}
              className="w-16 h-16 bg-zinc-800 border-2 border-zinc-700 flex items-center justify-center hover:bg-zinc-700 active:bg-zinc-950 transition-colors cursor-pointer disabled:cursor-not-allowed"
            >
              {activeBranch.enabled ? (
                <Check size={36} className="text-emerald-400" strokeWidth={3} />
              ) : (
                <X size={36} className="text-rose-400" strokeWidth={3} />
              )}
            </button>
          </div>
        </div>

        {/* 3. BOTTOM AREA (Task Status & Progress) */}
        <div className="flex flex-col gap-2 mt-2">
          
          {/* Status Text (Rigid min-height prevents layout shifts when empty) */}
          <div className="font-mono text-xs font-medium text-zinc-400 truncate min-h-[16px]">
            {task}
          </div>
          
          {/* Progress Bar */}
          <div className="w-full h-5 bg-zinc-950 border-2 border-zinc-700 relative overflow-hidden">
            <div 
              className="h-full bg-indigo-600 transition-all duration-300 ease-out"
              style={{ width: `${progress}%` }}
            ></div>
            <div className="absolute inset-0 opacity-15 pointer-events-none" style={{ backgroundImage: 'repeating-linear-gradient(45deg, transparent, transparent 8px, #000 8px, #000 16px)' }}></div>
          </div>
          
        </div>

      </div>
    </div>
  );
}