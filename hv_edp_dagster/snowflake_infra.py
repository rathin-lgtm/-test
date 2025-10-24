import re

from pydantic import BaseModel, field_validator

from hv_edp_dagster.constants import (
    IS_LOCAL_ENVIRONMENT,
    SHARED_DEV_BRONZE_PATH,
    FileTypes,
    Sources,
)


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


DATA_LANDING_STAGE = Stage(name="landing")


class FileFormat(SnowflakeResource):
    file_type: str

    def create_sql(self) -> str:
        sql = f"CREATE OR REPLACE FILE FORMAT {self.name} TYPE = {self.file_type}"
        if self.file_type == FileTypes.csv:
            sql += """, PARSE_HEADER = True, FIELD_DELIMITER = ",",
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'"""
        return sql


CSV_FILE_FORMAT = FileFormat(name="csv_file", file_type=FileTypes.csv)
PARQUET_FILE_FORMAT = FileFormat(name="parquet_file", file_type=FileTypes.parquet)


class Table(SnowflakeResource):
    source: str
    file_format: FileFormat

    def create_sql(
        self,
        db: str,
        schema: str,
        use_shared_stage: bool = True,
    ) -> str:
        if IS_LOCAL_ENVIRONMENT and use_shared_stage:
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


class BronzeTables:
    country = Table(name="COUNTRY", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT)
    currency = Table(name="CURRENCY", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT)
    dim_fund = Table(name="DIM_FUND", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT)
    fact_investment_transactions_fund_hierarchy_monthly = Table(
        name="FACT_INVESTMENT_TRANSACTIONS_FUND_HIERARCHY_MONTHLY",
        source=Sources.harbourview_edw,
        file_format=CSV_FILE_FORMAT,
    )
    fact_investor_transactions_fund_hierarchy = Table(
        name="FACT_INVESTOR_TRANSACTIONS_FUND_HIERARCHY",
        source=Sources.harbourview_edw,
        file_format=CSV_FILE_FORMAT,
    )
    fact_investor_transactions_monthly = Table(
        name="FACT_INVESTOR_TRANSACTIONS_MONTHLY",
        source=Sources.harbourview_edw,
        file_format=CSV_FILE_FORMAT,
    )
    fact_investor_transactions = Table(
        name="FACT_INVESTOR_TRANSACTIONS",
        source=Sources.harbourview_edw,
        file_format=CSV_FILE_FORMAT,
    )
    global_edw_key_to_iqid = Table(
        name="GLOBAL_EDW_KEY_TO_IQID", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT
    )
    dim_fund_sub_perspective = Table(
        name="DIM_FUND_SUB_PERSPECTIVE", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT
    )
    fact_fund_sub_perpective_funds = Table(
        name="FACT_FUND_SUB_PERSPECTIVE_FUNDS", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT
    )
    fact_fund_sub_perpective_fund_network_paths = Table(
        name="FACT_FUND_SUB_PERSPECTIVE_FUND_NETWORK_PATHS", source=Sources.harbourview_edw, file_format=CSV_FILE_FORMAT
    )


ALL_TABLES = [value for value in BronzeTables.__dict__.values() if isinstance(value, Table)]
ALL_FILE_FORMATS = [CSV_FILE_FORMAT, PARQUET_FILE_FORMAT]
