#!/usr/bin/env python3
"""
Integration tests for Aurora bootc image.
Tests basic functionality by connecting to a VM via SSH.
"""

import os
import sys
import time
import subprocess
import tempfile
from typing import List, Tuple


class SSHClient:
    def __init__(self, hostname: str, port: int, username: str, private_key: str):
        self.hostname = hostname
        self.port = port
        self.username = username
        
        # Write private key to temporary file
        self.key_file = tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.pem')
        self.key_file.write(private_key)
        self.key_file.close()
        
        # Set proper permissions on the key file
        os.chmod(self.key_file.name, 0o600)
    
    def __del__(self):
        # Clean up temporary key file
        if hasattr(self, 'key_file'):
            try:
                os.unlink(self.key_file.name)
            except FileNotFoundError:
                pass
    
    def run_command(self, command: str, timeout: int = 30) -> Tuple[int, str, str]:
        """Run a command via SSH and return (returncode, stdout, stderr)"""
        ssh_cmd = [
            'ssh',
            '-i', self.key_file.name,
            '-p', str(self.port),
            '-o', 'StrictHostKeyChecking=no',
            '-o', 'UserKnownHostsFile=/dev/null',
            '-o', 'LogLevel=ERROR',
            f'{self.username}@{self.hostname}',
            command
        ]
        
        try:
            result = subprocess.run(
                ssh_cmd,
                capture_output=True,
                text=True,
                timeout=timeout
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 124, "", f"Command timed out after {timeout} seconds"


def run_test(ssh_client: SSHClient, test_name: str, command: str, expected_text: str, max_retries: int = 3) -> bool:
    """Run a single test with retries"""
    print(f"Running test: {test_name}")
    
    for attempt in range(max_retries):
        if attempt > 0:
            print(f"  Retry {attempt}/{max_retries - 1}")
            time.sleep(5)
        
        returncode, stdout, stderr = ssh_client.run_command(command)
        
        if returncode != 0:
            print(f"  ❌ Command failed with exit code {returncode}")
            print(f"     stdout: {stdout.strip()}")
            print(f"     stderr: {stderr.strip()}")
            continue
        
        if expected_text in stdout:
            print(f"  ✅ PASS")
            return True
        else:
            print(f"  ❌ Expected '{expected_text}' not found in output")
            print(f"     stdout: {stdout.strip()}")
    
    print(f"  ❌ FAIL after {max_retries} attempts")
    return False


def main():
    # Get environment variables
    ssh_private_key = os.getenv('SSH_PRIVATE_KEY')
    ssh_port = int(os.getenv('SSH_PORT', '2222'))
    
    if not ssh_private_key:
        print("❌ SSH_PRIVATE_KEY environment variable not set")
        sys.exit(1)
    
    # Create SSH client
    ssh_client = SSHClient('localhost', ssh_port, 'ci-user', ssh_private_key)
    
    # Define tests
    tests = [
        ("KernelInstalled", "rpm -q kernel", "kernel"),
        ("CheckSELinuxStatus", "getenforce", "Enforcing"),
        ("CheckSudoersValid", "sudo visudo -cf /etc/sudoers", "/etc/sudoers: parsed OK"),
        ("CheckNftablesServiceEnabled", "systemctl is-enabled nftables", "enabled"),
        ("CheckNftablesServiceActive", "systemctl is-active nftables", "active"),
    ]
    
    print("Starting Aurora bootc integration tests...")
    print(f"Connecting to localhost:{ssh_port} as ci-user")
    
    passed = 0
    failed = 0
    
    for test_name, command, expected_text in tests:
        if run_test(ssh_client, test_name, command, expected_text):
            passed += 1
        else:
            failed += 1
    
    print(f"\nResults: {passed} passed, {failed} failed")
    
    if failed > 0:
        sys.exit(1)
    else:
        print("✅ All tests passed!")


if __name__ == "__main__":
    main()
