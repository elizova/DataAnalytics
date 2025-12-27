from sqlalchemy import (
    Column,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    String,
)
from src.database.database import base


class WeatherStationOrm(base):
    __tablename__ = "weather_station"

    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    city = Column(String(100), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    elevation_m = Column(Float, nullable=True)


class WeatherMeasurementOrm(base):
    __tablename__ = "weather_measurement"

    id = Column(Integer, primary_key=True)
    station_id = Column(
        Integer,
        ForeignKey("weather_station.id", ondelete="CASCADE"),
        nullable=False,
    )
    measured_at = Column(DateTime(timezone=True), nullable=False)

    temperature_c = Column(Float, nullable=False)
    humidity_pct = Column(Float, nullable=False)
    pressure_hpa = Column(Float, nullable=False)
    wind_speed_ms = Column(Float, nullable=False)
    wind_dir_deg = Column(Integer, nullable=False)
    precipitation_mm = Column(Float, nullable=False)
    condition = Column(String(32), nullable=False)

    __table_args__ = (
        Index(
            "ix_weather_measurement_station_time", "station_id", "measured_at"
        ),
    )
