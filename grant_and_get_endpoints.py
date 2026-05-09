# .deploy/grant_and_get_endpoints.py
#
# Phase 2 of the deployment workflow.
# This script does two things:
#
# 1. Calls the Fabric REST API to retrieve the SQL connection string
#    (endpoint) for each named warehouse in the target workspace.
#
# 2. Grants the service principal db_ddladmin on each warehouse
#    via pyodbc, which is required before SqlPackage can publish
#    schemas to it.
#
# Endpoints are written to GITHUB_ENV so subsequent workflow steps
# can use them as environment variables:
#   SOURCE_WH_ENDPOINT
#   TARGET_WH_ENDPOINT

import argparse
import os
import sys

import requests
import pyodbc
from azure.identity import ClientSecretCredential


def get_access_token(credential: ClientSecretCredential, scope: str) -> str:
    """Acquire an access token for the given scope."""
    token = credential.get_token(scope)
    return token.token


def get_sp_display_name(
    credential: ClientSecretCredential,
    client_id: str,
) -> str:
    """
    Looks up the service principal's display name in Entra ID
    via the Microsoft Graph API.
    Fabric Warehouse requires the display name in ALTER ROLE
    statements, not the client ID GUID.
    """
    token = get_access_token(credential, "https://graph.microsoft.com/.default")
    url = f"https://graph.microsoft.com/v1.0/servicePrincipals?$filter=appId eq '{client_id}'"
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()
    values = response.json().get("value", [])
    if not values:
        raise ValueError(
            f"Could not find service principal with appId {client_id} "
            f"in Microsoft Graph. Check the client ID is correct."
        )
    display_name = values[0]["displayName"]
    print(f"  SP display name: {display_name}")
    return display_name


def get_warehouse_endpoints(
    token: str,
    workspace_id: str,
    warehouse_names: list[str],
) -> dict[str, str]:
    """
    Calls the Fabric List Warehouses API and returns a dict of
    { warehouse_name: connection_string } for each named warehouse.
    Raises if any named warehouse is not found.
    """
    url = f"https://api.fabric.microsoft.com/v1/workspaces/{workspace_id}/warehouses"
    headers = {"Authorization": f"Bearer {token}"}

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()

    warehouses = response.json().get("value", [])

    found = {}
    for wh in warehouses:
        name = wh.get("displayName", "")
        connection_string = wh.get("properties", {}).get("connectionString", "")
        if name in warehouse_names:
            found[name] = connection_string
            print(f"  Found {name}: {connection_string}")

    missing = set(warehouse_names) - set(found.keys())
    if missing:
        raise ValueError(
            f"The following warehouses were not found in workspace {workspace_id}: "
            f"{', '.join(missing)}\n"
            f"Warehouses available: {[w['displayName'] for w in warehouses]}"
        )

    return found


def grant_db_ddladmin(
    endpoint: str,
    database: str,
    client_id: str,
    client_secret: str,
    sp_display_name: str,
) -> None:
    """
    Connects to a Fabric Warehouse via the service principal and
    grants db_ddladmin to the SP using its Entra display name.
    Fabric Warehouse resolves principals by display name, not
    client ID GUID.
    This is required for SqlPackage to publish schemas.
    """
    conn_str = (
        f"Driver={{ODBC Driver 18 for SQL Server}};"
        f"Server={endpoint},1433;"
        f"Database={database};"
        f"Authentication=ActiveDirectoryServicePrincipal;"
        f"UID={client_id};"
        f"PWD={client_secret};"
        f"Encrypt=Yes;"
        f"TrustServerCertificate=No;"
        f"Connection Timeout=30;"
    )

    print(f"  Connecting to {database} at {endpoint}...")
    conn = pyodbc.connect(conn_str, autocommit=True)
    cursor = conn.cursor()

    cursor.execute(
        f"ALTER ROLE db_ddladmin ADD MEMBER [{sp_display_name}]"
    )
    print(f"  Granted db_ddladmin to '{sp_display_name}' on {database}")

    cursor.close()
    conn.close()


def write_to_github_env(key: str, value: str) -> None:
    """
    Writes a key=value pair to the GITHUB_ENV file so it is
    available to all subsequent steps in the workflow job.
    """
    github_env = os.environ.get("GITHUB_ENV")
    if not github_env:
        print(f"  [LOCAL] Would set {key}={value}")
        return
    with open(github_env, "a") as f:
        f.write(f"{key}={value}\n")
    print(f"  Written to GITHUB_ENV: {key}={value}")


def main():
    parser = argparse.ArgumentParser(
        description="Retrieve Fabric warehouse endpoints and grant SP permissions"
    )
    parser.add_argument("--tenant-id",       required=True)
    parser.add_argument("--client-id",       required=True)
    parser.add_argument("--client-secret",   required=True)
    parser.add_argument("--workspace-id",    required=True)
    parser.add_argument(
        "--warehouse-names",
        required=True,
        help="Comma-separated warehouse display names e.g. Source_WH,Target_WH",
    )
    parser.add_argument(
        "--sp-object-id",
        required=False,
        default="",
        help="Object ID of the service principal — retained for future use",
    )

    args = parser.parse_args()
    warehouse_names = [n.strip() for n in args.warehouse_names.split(",")]

    # ------------------------------------------------------------------
    # Authenticate
    # ------------------------------------------------------------------
    print("\n--- Authenticating ---")
    credential = ClientSecretCredential(
        tenant_id=args.tenant_id,
        client_id=args.client_id,
        client_secret=args.client_secret,
    )

    fabric_token = get_access_token(
        credential, "https://api.fabric.microsoft.com/.default"
    )
    print("  Fabric token acquired")

    # ------------------------------------------------------------------
    # Look up SP display name from Entra ID via Graph API
    # ------------------------------------------------------------------
    print("\n--- Looking up SP display name ---")
    sp_display_name = get_sp_display_name(credential, args.client_id)

    # ------------------------------------------------------------------
    # Phase 2a: Retrieve warehouse endpoints
    # ------------------------------------------------------------------
    print("\n--- Retrieving warehouse endpoints ---")
    endpoints = get_warehouse_endpoints(
        token=fabric_token,
        workspace_id=args.workspace_id,
        warehouse_names=warehouse_names,
    )

    # ------------------------------------------------------------------
    # Phase 2b: Grant db_ddladmin and write endpoints to GITHUB_ENV
    # ------------------------------------------------------------------
    print("\n--- Granting db_ddladmin and writing endpoints ---")
    for name, endpoint in endpoints.items():
        print(f"\nProcessing {name}:")
        grant_db_ddladmin(
            endpoint=endpoint,
            database=name,
            client_id=args.client_id,
            client_secret=args.client_secret,
            sp_display_name=sp_display_name,
        )
        env_key = name.upper().replace(" ", "_") + "_ENDPOINT"
        write_to_github_env(env_key, endpoint)

    print("\n--- Phase 2 complete ---")


if __name__ == "__main__":
    main()