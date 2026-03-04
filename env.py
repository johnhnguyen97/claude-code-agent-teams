import os
import sys
import subprocess

if __name__ == '__main__':
    args = sys.argv[1:]
    env_vars = os.environ.copy()
    
    cmd_idx = 0
    for i, arg in enumerate(args):
        if '=' in arg:
            key, val = arg.split('=', 1)
            env_vars[key] = val
            cmd_idx = i + 1
        else:
            break
            
    if cmd_idx < len(args):
        cmd = args[cmd_idx:]
        try:
            # If the command is a node script, make sure we use 'node' to execute it
            if cmd[0].endswith('.js') and os.path.exists(cmd[0]):
                cmd = ['node'] + cmd
                
            result = subprocess.run(cmd, env=env_vars)
            sys.exit(result.returncode)
        except Exception as e:
            print(f"env shim error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        sys.exit(0)
