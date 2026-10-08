#!/usr/bin/env python3
"""Verify and package an existing tested APK. Does not upload or modify signing keys."""
import argparse,configparser,hashlib,json,os,re,shutil,subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--apk',type=Path,default=ROOT/'builds/schism-android-debug.apk')
p.add_argument('--output',type=Path,default=ROOT/'builds/sideload')
p.add_argument('--sdk',type=Path,default=os.environ.get('ANDROID_SDK_ROOT',os.environ.get('ANDROID_HOME')))
p.add_argument('--previous',type=Path,help='Verify update compatibility with an earlier APK')
a=p.parse_args()
def run(*command):return subprocess.check_output([str(x) for x in command],cwd=ROOT,text=True).strip()
def digest(path):return hashlib.sha256(path.read_bytes()).hexdigest()
if run('git','status','--porcelain'):raise SystemExit('Commit the tested source and evidence before packaging a distribution.')
if a.sdk is None:raise SystemExit('Set ANDROID_SDK_ROOT or pass --sdk /path/to/android/sdk.')
versions=[x for x in (a.sdk/'build-tools').iterdir() if (x/'aapt').is_file() and (x/'apksigner').is_file()]
if not versions:raise SystemExit('Android build tools are missing.')
tools=max(versions,key=lambda x:tuple(int(n) for n in re.findall(r'\d+',x.name)))
presets=configparser.ConfigParser();presets.read(ROOT/'mobile/export_presets.cfg')
expected_version=presets['preset.0.options']['version/name'].strip('"');expected_code=int(presets['preset.0.options']['version/code'])
badging=run(tools/'aapt','dump','badging',a.apk)
package=re.search(r"package: name='([^']+)' versionCode='(\d+)' versionName='([^']+)'",badging)
if not package or package.groups()!=('org.schism.districtix',str(expected_code),expected_version):raise SystemExit('APK package/version does not match the committed Android preset.')
def certificate(path):
 verified=run(tools/'apksigner','verify','--print-certs',path)
 match=re.search(r'Signer #1 certificate SHA-256 digest: ([a-f0-9]{64})',verified)
 if not match:raise SystemExit('APK has no verified signing certificate.')
 return match.group(1)
signer=certificate(a.apk)
if a.previous:
 old_badging=run(tools/'aapt','dump','badging',a.previous)
 old_package=re.search(r"package: name='([^']+)' versionCode='(\d+)'",old_badging)
 if not old_package or old_package.group(1)!=package.group(1) or int(old_package.group(2))>=expected_code or certificate(a.previous)!=signer:
  raise SystemExit('APK cannot upgrade the selected previous build: package, version code or signing certificate differs.')
a.output.mkdir(parents=True,exist_ok=True)
filename=f'schism-{expected_version}.apk';target=a.output/filename;sha=digest(a.apk)
if target.exists() and digest(target)!=sha:raise SystemExit('This version is already packaged with different bytes. Bump the version instead of replacing a distributed APK.')
if not target.exists():shutil.copyfile(a.apk,target)
manifest={'game':'SCHISM','version':expected_version,'version_code':expected_code,'package':package.group(1),'source_commit':run('git','rev-parse','HEAD'),'file':filename,'bytes':target.stat().st_size,'sha256':sha,'signer_certificate_sha256':signer,'minimum_android_api':int(re.search(r"sdkVersion:'(\d+)'",badging).group(1)),'target_android_api':int(re.search(r"targetSdkVersion:'(\d+)'",badging).group(1)),'channel':'sideload development preview','save_schema':int(re.search(r'^const SCHEMA = (\d+)$',(ROOT/'mobile/src/simulation.gd').read_text(),re.M).group(1))}
manifest_path=a.output/'manifest.json';manifest_path.write_text(json.dumps(manifest,indent=2)+'\n')
(a.output/'SHA256SUMS').write_text(f'{sha}  {filename}\n{digest(manifest_path)}  manifest.json\n')
print(json.dumps(manifest,indent=2))
