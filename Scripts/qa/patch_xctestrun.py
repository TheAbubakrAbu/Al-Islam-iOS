#!/usr/bin/env python3
"""patch_xctestrun.py <in.xctestrun> <out.xctestrun> <target> --args "<launch args>" --env K=V ... [--allowance N]

Copies an xctestrun and sets the host app's command line arguments and the test bundle's
environment for one test target (the host app's args for a hosted target, the UI target app's args
for a UI test bundle). The copy must live NEXT TO the original: its paths are __TESTROOT__-relative.
"""
import plistlib, shlex, sys, argparse

ap = argparse.ArgumentParser()
ap.add_argument('src'); ap.add_argument('dst'); ap.add_argument('target')
ap.add_argument('--args', default='')
ap.add_argument('--env', action='append', default=[])
ap.add_argument('--allowance', type=int, default=0, help='DefaultTestExecutionTimeAllowance seconds')
a = ap.parse_args()

d = plistlib.load(open(a.src, 'rb'))
hit = False
for cfg in d.get('TestConfigurations', []):
    for t in cfg['TestTargets']:
        if t.get('BlueprintName') != a.target:
            continue
        hit = True
        args = shlex.split(a.args)
        if t.get('IsUITestBundle'):
            t['UITargetAppCommandLineArguments'] = args
        else:
            t['CommandLineArguments'] = args
        env = dict(t.get('EnvironmentVariables') or {})
        tenv = dict(t.get('TestingEnvironmentVariables') or {})
        for kv in a.env:
            k, v = kv.split('=', 1)
            env[k] = v
            tenv[k] = v
        t['EnvironmentVariables'] = env
        t['TestingEnvironmentVariables'] = tenv
        if a.allowance:
            t['TestTimeoutsEnabled'] = True
            t['DefaultTestExecutionTimeAllowance'] = a.allowance
if not hit:
    sys.exit(f'no target {a.target}')
plistlib.dump(d, open(a.dst, 'wb'))
print('patched', a.dst, 'args:', a.args, 'env:', a.env)
