"""DAG Airflow 3.2.0 : pipeline R sur MinIO (S3-compatible).

Lit la connexion Airflow `minio-s3-hp` (type AWS Web Service ; le champ Extra
contient `endpoint_url` et `bucket`), passe les credentials/endpoint/bucket
au script R via des variables d'environnement, puis execute Rscript.
"""

from __future__ import annotations

import os
import subprocess
from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG, BaseHook, task

DAG_DIR = os.path.dirname(os.path.abspath(__file__))
R_SCRIPT = os.path.join(DAG_DIR, "scripts", "example.R")

CONN_ID = "minio-s3-hp"

default_args = {
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}


with DAG(
    dag_id="example_r_pipeline",
    description="Pipeline R sur MinIO : lit file.csv, ajoute une colonne total, uploade le resultat.",
    default_args=default_args,
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["r", "example"],
) as dag:

    check_r = BashOperator(
        task_id="check_r_available",
        bash_command="Rscript --version && which Rscript ",
    )

    @task(task_id="run_r_s3_pipeline")
    def run_r_s3_pipeline() -> None:
        conn = BaseHook.get_connection(CONN_ID)
        extra = conn.extra_dejson
        env = {
            **os.environ,
            "AWS_ACCESS_KEY_ID": conn.login or "",
            "AWS_SECRET_ACCESS_KEY": conn.password or "",
            "S3_ENDPOINT_URL": extra["endpoint_url"],
            "S3_BUCKET": extra["bucket"],
        }
        subprocess.run(["Rscript", R_SCRIPT], env=env, check=True)

    check_r >> run_r_s3_pipeline()
