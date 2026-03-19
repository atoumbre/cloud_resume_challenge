#!/usr/bin/env python3
"""
Optional local deployment helper for the Cloud Resume Challenge.

This script mirrors the current repo flow:
1. Apply Terraform from infra/
2. Read Terraform outputs
3. Build the Astro frontend with PUBLIC_API_URL
4. Sync frontend/dist/ to the provisioned S3 bucket
5. Invalidate the CloudFront distribution
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
INFRA_DIR = ROOT / "infra"
FRONTEND_DIR = ROOT / "frontend"
ENV_FILE = ROOT / ".env"


def load_env_file() -> None:
    """Load simple KEY=VALUE pairs from a local .env file if present."""
    if not ENV_FILE.exists():
        return

    print(f"Loading environment from {ENV_FILE}")
    for raw_line in ENV_FILE.read_text().splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("export "):
            line = line[7:]
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ[key.strip()] = value.strip().strip("\"'")


def require_tools(*tool_names: str) -> None:
    missing = [tool for tool in tool_names if shutil.which(tool) is None]
    if missing:
        print(f"Missing required tools: {', '.join(missing)}", file=sys.stderr)
        sys.exit(1)


def run_command(
    cmd: list[str],
    *,
    cwd: Path | None = None,
    capture: bool = False,
    env: dict[str, str] | None = None,
) -> str:
    try:
        result = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            check=True,
            text=True,
            capture_output=capture,
            env=env,
        )
    except subprocess.CalledProcessError as exc:
        print(f"Command failed: {' '.join(cmd)}", file=sys.stderr)
        if exc.stderr:
            print(exc.stderr, file=sys.stderr)
        sys.exit(exc.returncode)

    return result.stdout.strip() if capture else ""


def terraform_outputs() -> dict[str, object]:
    output = run_command(["terraform", "output", "-json"], cwd=INFRA_DIR, capture=True)
    return json.loads(output)


def main() -> None:
    load_env_file()
    require_tools("aws", "terraform", "npm", "python3")

    print("Checking AWS caller identity")
    run_command(["aws", "sts", "get-caller-identity"], capture=True)

    print("Initializing Terraform")
    run_command(["terraform", "init", "-input=false"], cwd=INFRA_DIR)

    print("Applying Terraform")
    run_command(["terraform", "apply", "-auto-approve", "-input=false"], cwd=INFRA_DIR)

    outputs = terraform_outputs()
    frontend_bucket = outputs["frontend_s3_bucket_name"]["value"]
    api_endpoint = outputs["api_endpoint"]["value"]
    distribution_id = outputs["cloudfront_distribution_id"]["value"]
    website_url = outputs.get("website_url", {}).get("value")

    print("Installing frontend dependencies")
    run_command(["npm", "install"], cwd=FRONTEND_DIR)

    print("Building Astro frontend")
    frontend_env = os.environ.copy()
    frontend_env["PUBLIC_API_URL"] = str(api_endpoint)
    run_command(["npm", "run", "build"], cwd=FRONTEND_DIR, env=frontend_env)

    print(f"Syncing frontend/dist to s3://{frontend_bucket}")
    run_command(
        ["aws", "s3", "sync", "dist/", f"s3://{frontend_bucket}", "--delete"],
        cwd=FRONTEND_DIR,
    )

    print(f"Invalidating CloudFront distribution {distribution_id}")
    run_command(
        [
            "aws",
            "cloudfront",
            "create-invalidation",
            "--distribution-id",
            str(distribution_id),
            "--paths",
            "/*",
        ],
        capture=True,
    )

    print("Local deployment complete")
    print(f"API endpoint: {api_endpoint}")
    if website_url:
        print(f"Website URL: {website_url}")


if __name__ == "__main__":
    main()
