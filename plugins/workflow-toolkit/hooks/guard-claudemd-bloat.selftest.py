import json, subprocess, tempfile, os
H="/Users/piotrkozlowski/Documents/piotr-toolkit/plugins/workflow-toolkit/hooks/guard-claudemd-bloat.sh"
d=tempfile.mkdtemp(); F=os.path.join(d,"CLAUDE.md"); A=os.path.join(d,"AGENTS.md")
env=dict(os.environ); env["CLAUDE_PROJECT_DIR"]=d
def w(n,p=F): open(p,"w").write("x\n"*n)
def run(ev,tool,ti):
    p={"hook_event_name":ev,"tool_name":tool,"tool_input":ti}
    return subprocess.run(["bash",H],input=json.dumps(p),capture_output=True,text=True,cwd=d,env=env).returncode
P=F_=0
def chk(name,got,exp):
    global P,F_
    if got==exp: P+=1; print(f"  ok   {name} (exit {got})")
    else: F_+=1; print(f"  FAIL {name}: exit {got} != {exp}")

print("== Pre/Bash — cel dopisania ==")
w(300); chk("dopisanie >> do pliku NAD limitem",            run("PreToolUse","Bash",{"command":f"echo x >> {F}"}),2)
w(100); chk("dopisanie >> do pliku POD limitem (regresja)", run("PreToolUse","Bash",{"command":f"echo x >> {F}"}),0)
w(100); w(300,A); chk("dopisanie do AGENTS.md nad limitem", run("PreToolUse","Bash",{"command":f"echo x >> {A}"}),2)
w(100); w(300,A); chk("dopisanie do CLAUDE.md pod limitem, gdy AGENTS nad", run("PreToolUse","Bash",{"command":f"echo x >> {F}"}),0)
w(300); chk("tee -a na plik nad limitem",                   run("PreToolUse","Bash",{"command":f"echo x | tee -a {F}"}),2)
w(300); chk("sed -i (nieznana delta, moze byc konsolidacja)",run("PreToolUse","Bash",{"command":f"sed -i '' 1d {F}"}),0)
w(300); chk("sam odczyt grep",                              run("PreToolUse","Bash",{"command":f"grep -n x {F}"}),0)
chk("komenda bez pliku instrukcji",                         run("PreToolUse","Bash",{"command":"ls -la /tmp"}),0)
w(300); chk("zapis przez zmienna (cel nie do wylowienia) → Post lapie", run("PreToolUse","Bash",{"command":"echo x >> $TARGET_CLAUDE.md"}),0)

os.remove(A)  # izolacja: AGENTS.md z poprzednich case'ow nie moze zaklocac warstwy Post
print("== Post/Bash ==")
w(300); chk("nad limitem, swiezy mtime → wykryte", run("PostToolUse","Bash",{"command":"python3 s.py"}),2)
w(200); chk("pod limitem, swiezy mtime → cisza",   run("PostToolUse","Bash",{"command":"python3 s.py"}),0)
w(300); os.utime(F,(0,0)); chk("nad limitem, stary mtime → cisza", run("PostToolUse","Bash",{"command":"ls"}),0)

print("== Pre/Write-Edit (regresja) ==")
w(100); chk("Write 300 linii",  run("PreToolUse","Write",{"file_path":F,"content":"x\n"*300}),2)
w(100); chk("Write 100 linii",  run("PreToolUse","Write",{"file_path":F,"content":"x\n"*100}),0)
w(239); chk("Edit +5 ponad limit", run("PreToolUse","Edit",{"file_path":F,"old_string":"a","new_string":"a\nb\nc\nd\ne\nf"}),2)
w(239); chk("Edit skracajacy",     run("PreToolUse","Edit",{"file_path":F,"old_string":"a\nb\nc","new_string":"a"}),0)
chk("plik nie-instrukcja (README.md)", run("PreToolUse","Write",{"file_path":os.path.join(d,"README.md"),"content":"x\n"*300}),0)
print(f"\npass:{P} fail:{F_}")
raise SystemExit(1 if F_ else 0)
