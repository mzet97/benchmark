#!/usr/bin/env python3
"""Run a long-running command on the K3s server detached, write output to a file, poll until done."""
import paramiko
import sys
import time

SERVER = "192.168.1.51"
USER = "k8s1"
PASSWORD = "Admin@123"


def main():
    if len(sys.argv) < 2:
        print("Usage: ssh_run.py <script_path_local> [max_wait_seconds]", file=sys.stderr)
        sys.exit(2)
    script_local = sys.argv[1]
    max_wait = int(sys.argv[2]) if len(sys.argv) > 2 else 600

    with open(script_local, "r", encoding="utf-8") as f:
        content = f.read()

    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=15)

    remote_script = "/tmp/zcode_run.sh"
    out_file = "/tmp/zcode_run.out"
    done_file = "/tmp/zcode_run.done"

    sftp = ssh.open_sftp()
    with sftp.open(remote_script, "w") as rf:
        rf.write(content)
    sftp.chmod(remote_script, 0o755)
    sftp.close()

    cmd = (
        f"rm -f {out_file} {done_file}; "
        f"nohup bash -c 'bash {remote_script} > {out_file} 2>&1; echo EXITCODE=$? > {done_file}' >/dev/null 2>&1 & "
        "echo STARTED"
    )
    stdin, stdout, stderr = ssh.exec_command(cmd, timeout=30)
    started = stdout.read().decode("utf-8", errors="replace")
    print(f"[launch] {started.strip()}", flush=True)
    ssh.close()

    start = time.time()
    while time.time() - start < max_wait:
        time.sleep(8)
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=15)
        stdin, stdout, stderr = ssh.exec_command(f"cat {done_file} 2>/dev/null", timeout=20)
        done = stdout.read().decode("utf-8", errors="replace").strip()
        stdin, stdout, stderr = ssh.exec_command(f"cat {out_file} 2>/dev/null", timeout=20)
        out_so_far = stdout.read().decode("utf-8", errors="replace")
        ssh.close()
        if done:
            print(f"[done] {done}", flush=True)
            print(out_so_far, flush=True)
            try:
                ec = int(done.split("=")[1].split()[0])
            except Exception:
                ec = 0
            sys.exit(ec)
        last = out_so_far.strip().splitlines()[-1] if out_so_far.strip() else "(no output yet)"
        print(f"[wait {int(time.time()-start)}s] {last}", flush=True)

    print("[TIMEOUT] max_wait exceeded. Partial output:", flush=True)
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(SERVER, username=USER, password=PASSWORD, timeout=15)
    stdin, stdout, stderr = ssh.exec_command(f"cat {out_file} 2>/dev/null", timeout=20)
    print(stdout.read().decode("utf-8", errors="replace"), flush=True)
    ssh.close()
    sys.exit(3)


if __name__ == "__main__":
    main()
