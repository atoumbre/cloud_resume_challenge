#!/usr/bin/env python3
"""
Local Deployment Script for Cloud Resume Challenge
Automates Infra provision, API URL injection, and Frontend asset sync using Python.
"""

import os
import sys
import json
import subprocess

# 1. Load Local .env Support (Saves Pip Install dependencies)
def load_env():
    """Manual parser to source bash-style .env parameters into the os environment."""
    env_path = os.path.join(os.getcwd(), '.env')
    if os.path.exists(env_path):
        print("💡 Sourcing local .env file...")
        with open(env_path, 'r') as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                if line.startswith('export '):
                    line = line[7:]
                if '=' in line:
                    key, value = line.split('=', 1)
                    os.environ[key.strip()] = value.strip('"\' ')

# 2. Command Runner Wrapper (Strict execution like set -e)
def run_command(cmd, cwd=None, capture=False):
    """Wrapper to run a list execution process and handle error states raising."""
    try:
        if capture:
            result = subprocess.run(cmd, cwd=cwd, check=True, text=True, capture_output=True)
            return result.stdout.strip()
        else:
            subprocess.run(cmd, cwd=cwd, check=True)
            return ""
    except subprocess.CalledProcessError as e:
        print(f"❌ Error executing: {' '.join(cmd)}")
        if getattr(e, 'stderr', None):
            print(f"Details:\n{e.stderr}")
        sys.exit(1)

def main():
    load_env()
    print("🚀 Starting Local Deployment via Python...")

    # 1. AWS Credentials Verification
    print("\n----------------------------------------")
    print("Checking AWS Authorization...")
    print("----------------------------------------")
    run_command(["aws", "sts", "get-caller-identity"], capture=True)

    infra_dir = os.path.join(os.getcwd(), "infra")

    # 2. Provision Infrastructure (Terraform)
    print("\n----------------------------------------")
    print("📦 1. Provisioning AWS Infrastructure...")
    print("----------------------------------------")
    print("Initializing Terraform...")
    run_command(["terraform", "init", "-input=false"], cwd=infra_dir)

    print("Applying Terraform configuration...")
    run_command(["terraform", "apply", "-auto-approve", "-input=false"], cwd=infra_dir)

    # Extract useful outputs via JSON for 100% precision
    print("\n🔍 Extracting live endpoints...")
    output_res = run_command(["terraform", "output", "-json"], cwd=infra_dir, capture=True)
    outputs = json.loads(output_res)

    try:
        frontend_bucket = outputs["frontend_s3_bucket_name"]["value"]
        api = outputs["api_endpoint"]["value"]
        distribution_id = outputs["cloudfront_distribution_id"]["value"]
    except KeyError as e:
        print(f"❌ Error: Missing expected Terraform output: {e}")
        sys.exit(1)

    # 3. Update Frontend API Endpoint in main.js
    print("\n----------------------------------------")
    print("🔧 2. Updating Frontend API Gateway URL...")
    print("----------------------------------------")
    js_path = os.path.join(os.getcwd(), "frontend", "main.js")
    
    with open(js_path, 'r') as f:
        lines = f.readlines()

    output_lines = []
    for line in lines:
        if line.strip().startswith('const API_URL ='):
            output_lines.append(f'const API_URL = "{api}/count";\n')
        else:
            output_lines.append(line)

    with open(js_path, 'w') as f:
        f.writelines(output_lines)
    print("✅ API URL successfully injected into main.js")

    # 4. Deploy Frontend to S3
    print("\n----------------------------------------")
    print("📤 3. Syncing Static Website to S3...")
    print("----------------------------------------")
    print(f"Syncing paths to Bucket: {frontend_bucket}")
    run_command(["aws", "s3", "sync", "frontend/", f"s3://{frontend_bucket}", "--delete"])

    # 5. Invalidate CloudFront Cache
    print("\n----------------------------------------")
    print("⚡ 4. Invalidating CloudFront Cache Distribution...")
    print("----------------------------------------")
    print(f"Submitting invalidation for {distribution_id}...")
    run_command(["aws", "cloudfront", "create-invalidation", "--distribution-id", distribution_id, "--paths", "/*"], capture=True)
    print("✅ Invalidation submitted.")

    print("\n----------------------------------------")
    print("🎉 Local Deployment Complete!")
    print("----------------------------------------")
    print(f"📍 API endpoint: {api}")
    print(f"📍 S3 Bucket:    {frontend_bucket}")

if __name__ == "__main__":
    main()
