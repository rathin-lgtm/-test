from contextlib import contextmanager
from typing import Generator, Optional, Self

from dagster import ConfigurableResource
from dagster_snowflake import SnowflakeResource
from pydantic import (
    Field,
    PrivateAttr,
    ValidationInfo,
    field_validator,
    model_validator,
)
from snowflake.connector.connection import SnowflakeConnection


class SnowflakeConnectionManager:
    """Manages Snowflake connections with support for both shared and per-asset connections."""

    def __init__(self) -> None:
        self._shared_connection: SnowflakeConnection | None = None

    def setup_shared_connection(self, snowflake_resource: SnowflakeResource) -> None:
        conn = snowflake_resource.get_connection().__enter__()
        self._shared_connection = conn

    def get_shared_connection(self) -> Optional[SnowflakeConnection]:
        return self._shared_connection

    def clear_shared_connection(self) -> None:
        if self._shared_connection:
            try:
                self._shared_connection.close()
            except Exception:
                pass
            self._shared_connection = None


class SnowflakeConfig(ConfigurableResource):
    account: str = Field(description="Snowflake account identifier")
    user: str = Field(description="Snowflake username")
    warehouse: str = Field(description="Snowflake warehouse")
    database: str = Field(description="Snowflake database")
    schema_bronze: str = Field(description="Snowflake schema bronze")
    role: str = Field(description="Snowflake role")
    stage: str = Field(description="Snowflake stage name")
    private_key_path: str | None = Field(description="Snowflake private key path")
    private_key_password: str | None = Field(description="Snowflake private key passphrase")
    authenticator: str | None = Field(description="Snowflake authenticator")
    use_shared_connection: bool = Field(
        default=False, description="Whether to use shared connection across assets"
    )
    _connection_manager: SnowflakeConnectionManager = PrivateAttr(
        default=SnowflakeConnectionManager()
    )

    @field_validator("account", "user", "warehouse", "database", "schema_bronze", "role")
    @classmethod
    def validate_required_fields(cls, value: str, info: ValidationInfo) -> str:
        if not value or not value.strip():
            raise ValueError(f"Required field {info.field_name} cannot be empty")
        return value.strip()

    @model_validator(mode="after")
    def validate_authentication_method(self) -> Self:
        if not self.authenticator and not (self.private_key_path and self.private_key_password):
            raise ValueError(
                "Either 'authenticator' must be set OR both 'private_key_path' and "
                "'private_key_password' must be set for authentication"
            )
        return self

    @property
    def _snowflake_resource(self) -> SnowflakeResource:
        return SnowflakeResource(
            account=self.account,
            user=self.user,
            private_key_path=self.private_key_path,
            private_key_password=self.private_key_password,
            authenticator=self.authenticator,
            warehouse=self.warehouse,
            database=self.database,
            schema=self.schema_bronze,
            role=self.role,
        )

    @contextmanager
    def get_connection(self) -> Generator[SnowflakeConnection, None, None]:
        if self.use_shared_connection:
            shared_conn = self._connection_manager.get_shared_connection()
            if shared_conn:
                yield shared_conn
            else:
                self._connection_manager.setup_shared_connection(self._snowflake_resource)
                connection = self._connection_manager.get_shared_connection()
                if connection:
                    yield connection
                else:
                    raise Exception("Unable to get the connection")
        else:
            with self._snowflake_resource.get_connection() as conn:
                yield conn

    def clear_shared_connection(self):
        self._connection_manager.clear_shared_connection()

    def get_full_stage_path(self) -> str:
        return f"{self.database}.{self.schema_bronze}.{self.stage}"


class JobConfig(ConfigurableResource):
    full_reload: bool | None = Field(
        default=None, description="Whether to perform a full reload of data"
    )
    stage_location: str | None = Field(
        default=None, description="Stage location to use (for personal_dev)"
    )
