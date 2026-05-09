# .deploy/deploy.py

import argparse
import json
import os
from pathlib import Path

from azure.identity import ClientSecretCredential
from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items


def main():
    parser = argparse.ArgumentParser(description="Deploy Fabric items to target workspace")

    parser.add_argument("--tenant-id",       required=True, help="Azure Entra tenant ID")
    parser.add_argument("--client-id",       required=True, help="Service Principal client ID")
    parser.add_argument("--client-secret",   required=True, help="Service Principal client secret")
    parser.add_argument("--target-env",      required=True, help="Target environment name (e.g. prod)")
    parser.add_argument("--workspace-name",  required=True, help="Target Fabric workspace name")
    parser.add_argument("--git-directory",   required=True, help="Folder containing Fabric items (e.g. fabric)")
    parser.add_argument(
        "--items-in-scope",
        required=False,
        default='["Notebook","DataPipeline","Warehouse"]',
        help="JSON array of Fabric item types to deploy"
    )

    args = parser.parse_args()

    items_in_scope = json.loads(args.items_in_scope)

    credential = ClientSecretCredential(
        tenant_id=args.tenant_id,
        client_id=args.client_id,
        client_secret=args.client_secret,
    )

    repo_root = Path(__file__).resolve().parent.parent
    repository_directory = str(repo_root / args.git_directory)

    # DEBUG — remove after first successful deployment
    print(f"Script location    : {Path(__file__).resolve()}")
    print(f"Repo root          : {repo_root}")
    print(f"Repository dir     : {repository_directory}")
    print(f"Directory exists   : {os.path.exists(repository_directory)}")
    print(f"Directory contents : {os.listdir(repository_directory) if os.path.exists(repository_directory) else 'NOT FOUND'}")

    print(f"Target environment : {args.target_env}")
    print(f"Target workspace   : {args.workspace_name}")
    print(f"Items in scope     : {items_in_scope}")

    workspace = FabricWorkspace(
        workspace_name=args.workspace_name,
        environment=args.target_env,
        repository_directory=repository_directory,
        item_type_in_scope=items_in_scope,
        token_credential=credential,
    )

    publish_all_items(workspace)
    unpublish_all_orphan_items(workspace)


if __name__ == "__main__":
    main()