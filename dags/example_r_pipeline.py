"""Exemple de DAG Airflow 3.2.0 executant un script R via tidyverse.

Pre-requis : l'image Docker doit fournir `Rscript` dans le PATH (cf. Dockerfile
de ce projet, qui installe R via rig et tidyverse au build).
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from airflow.providers.standard.operators.bash import BashOperator
from airflow.sdk import DAG

DAG_DIR = os.path.dirname(os.path.abspath(__file__))
R_SCRIPT = os.path.join(DAG_DIR, "scripts", "hello_tidyverse.R")
OUTPUT_CSV = "/tmp/hello_tidyverse.csv"

default_args = {
    "depends_on_past": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="example_r_pipeline",
    description="Exemple minimal : execute un script R (tidyverse) depuis Airflow.",
    default_args=default_args,
    schedule="@daily",
    start_date=datetime(2026, 1, 1),
    catchup=False,
    tags=["example", "r", "tidyverse"],
) as dag:

    check_r = BashOperator(
        task_id="check_r_available",
        # Espace final = pas de rendu Jinja (le contenu n'est pas un fichier .sh).
        bash_command="Rscript --version && which Rscript ",
    )

    run_r_script = BashOperator(
        task_id="run_hello_tidyverse",
        bash_command=f"Rscript {R_SCRIPT} {OUTPUT_CSV} ",
        env={"R_LIBS_USER": "/dev/null"},
    )

    show_output = BashOperator(
        task_id="show_csv_head",
        bash_command=f"echo '--- {OUTPUT_CSV} ---' && head -n 20 {OUTPUT_CSV} ",
    )

    check_r >> run_r_script >> show_output
