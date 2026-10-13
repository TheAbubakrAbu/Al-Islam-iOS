#!/usr/bin/env python3
"""write_mac_scheme.py "<launch args>": writes the private QA-Mac scheme (xcuserdata, git-ignored) from the
shared iPhone scheme with those launch arguments and a launch WITHOUT the debugger (a crash then writes an
.ips report instead of stopping in lldb). Xcode re-reads the file by itself within ~20 s of a change."""
import sys, html, os, getpass
root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
dst = f'{root}/Al-Islam.xcodeproj/xcuserdata/{getpass.getuser()}.xcuserdatad/xcschemes/QA-Mac.xcscheme'
os.makedirs(os.path.dirname(dst), exist_ok=True)
args = sys.argv[1]
t = open(f'{root}/Al-Islam.xcodeproj/xcshareddata/xcschemes/iPhone.xcscheme').read()
t = t.replace('selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"\n      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"\n      launchStyle = "0"',
              'selectedDebuggerIdentifier = ""\n      selectedLauncherIdentifier = "Xcode.IDEFoundation.Launcher.PosixSpawn"\n      launchStyle = "0"', 1)
assert 'PosixSpawn' in t, 'launch action anchor not found in iPhone.xcscheme'
block = ('      <CommandLineArguments>\n         <CommandLineArgument\n            argument = "%s"\n'
         '            isEnabled = "YES">\n         </CommandLineArgument>\n      </CommandLineArguments>\n') % html.escape(args, quote=True)
i = t.index('   </LaunchAction>')
open(dst, 'w').write(t[:i] + block + t[i:])
print('QA-Mac scheme:', args)
