import re
from enum import Enum
from pathlib import Path

import yaml
from pydantic import BaseModel, field_validator

from hv_edp_dagster.constants import (
    SHARED_DEV_BRONZE_PATH,
    FileTypes,
    SnowflakeEnv,
    Sources,
)
from hv_edp_dagster.utils import get_dbt_project_dir


def validate_snowflake_identifier(name: str) -> str:
    """
    Validate that a name is a valid Snowflake identifier.

    Rules:
    - Must start with a letter (A-Z, a-z) or underscore (_)
    - Can only contain letters, digits (0-9), underscores (_), and dollar signs ($)
    - Cannot be empty
    """
    if not name:
        raise ValueError("Name cannot be empty")

    if not re.match(r"^[A-Za-z_][A-Za-z0-9_$]*$", name):
        raise ValueError(
            f"Invalid identifier '{name}': must start with letter or underscore "
            "and contain only letters, digits, underscores, and dollar signs"
        )

    return name


class SnowflakeResource(BaseModel):
    name: str

    @field_validator("name")
    @classmethod
    def validate_name(cls, v: str) -> str:
        return validate_snowflake_identifier(v)


class Stage(SnowflakeResource):
    def create_sql(self, db: str, schema: str) -> str:
        return (
            f"CREATE STAGE IF NOT EXISTS {db}.{schema}.{self.name} DIRECTORY = ( ENABLE = TRUE );"
        )


class FileFormat(SnowflakeResource):
    file_type: str

    def create_sql(self, header: bool = True, delimiter: str = ",", enclosed_by: str = '"') -> str:
        sql = f"CREATE OR REPLACE FILE FORMAT {self.name} TYPE = {self.file_type}"
        if self.file_type == FileTypes.CSV:
            sql += f""", PARSE_HEADER = {header}, FIELD_DELIMITER = "{delimiter}",
            FIELD_OPTIONALLY_ENCLOSED_BY = '{enclosed_by}'"""
        return sql


DATA_LANDING_STAGE = Stage(name="landing")


class Table(SnowflakeResource):
    source: str
    file_format: FileFormat

    def create_sql(
        self,
        db: str,
        schema: str,
        use_shared_stage: bool = True,
    ) -> str:
        if SnowflakeEnv.IS_LOCAL_ENVIRONMENT and use_shared_stage:
            inferred_data_location = SHARED_DEV_BRONZE_PATH
        else:
            inferred_data_location = f"{db}.{schema}"
        full_file_path = (
            f"{inferred_data_location}.{DATA_LANDING_STAGE.name}/{self.source}/{self.name}/"
        )
        return f"""CREATE TABLE IF NOT EXISTS {db}.{schema}.{self.name}
                        USING TEMPLATE (
                            SELECT ARRAY_CAT(
                               ARRAY_AGG(
                                    OBJECT_CONSTRUCT(
                                        'COLUMN_NAME', UPPER(COLUMN_NAME),
                                        'TYPE', 'STRING',
                                        'NULLABLE', NULLABLE,
                                        'EXPRESSION', EXPRESSION,
                                        'FILENAMES', FILENAMES,
                                        'ORDER_ID', ORDER_ID)),
                               ARRAY_CONSTRUCT(
                                 OBJECT_CONSTRUCT('COLUMN_NAME','INGEST_TIME',
                                                  'TYPE','TIMESTAMP_LTZ',
                                                  'NULLABLE', True),
                                 OBJECT_CONSTRUCT('COLUMN_NAME','FILE_NAME',
                                                  'TYPE','STRING',
                                                  'NULLABLE', True),
                                 OBJECT_CONSTRUCT('COLUMN_NAME', 'FILE_DATE',
                                                  'TYPE','DATE',
                                                  'NULLABLE', True)
                               )
                             )
                  FROM TABLE(
                    INFER_SCHEMA(
                    LOCATION => '@{full_file_path}',
                    FILE_FORMAT => '{self.file_format.name}',
                    MAX_FILE_COUNT => 10
                    )
                  )
                );"""


class FileFormats(Enum):
    CSV = FileFormat(name="csv_file", file_type=FileTypes.CSV)
    PARQUET = FileFormat(name="parquet_file", file_type=FileTypes.PARQUET)


ALL_FILE_FORMATS = [file_format.value for file_format in FileFormats]


def load_bronze_table_definition_fron_dbt() -> list[Table]:
    try:
        config_path = Path(get_dbt_project_dir(), "models", "sources.yml")
        with open(config_path) as f:
            config_data = yaml.safe_load(f)
        table_definitions = []
        for source in config_data["sources"]:
            for table in source["tables"]:
                table_definitions.append(
                    Table(
                        name=table["name"].upper(),
                        source=Sources[source["meta"]["source_db"]].value,
                        file_format=FileFormats[source["meta"]["source_file_format"]].value,
                    )
                )
        return table_definitions
    except Exception:
        raise Exception("Error loading sources.yml occured, make sure it has valid data.")


ALL_TABLES = load_bronze_table_definition_fron_dbt()
