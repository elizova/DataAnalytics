import asyncio
import math
import random
from datetime import datetime, timezone
from typing import List

from sqlalchemy import select
from src.database.database import get_session
from src.database.models import WeatherMeasurementOrm, WeatherStationOrm

STATIONS = [
    {
        "name": "Station Center",
        "city": "Metropolis",
        "lat": 55.7558,
        "lon": 37.6173,
        "elev": 144,
    },
    {
        "name": "Station North",
        "city": "Northville",
        "lat": 60.0,
        "lon": 40.0,
        "elev": 200,
    },
    {
        "name": "Station South",
        "city": "Southtown",
        "lat": 48.0,
        "lon": 30.0,
        "elev": 50,
    },
    {
        "name": "Station East",
        "city": "Eastburg",
        "lat": 52.0,
        "lon": 45.0,
        "elev": 100,
    },
    {
        "name": "Station West",
        "city": "Westport",
        "lat": 50.0,
        "lon": 25.0,
        "elev": 75,
    },
]


base_temp_by_lat = {
    60: -5.0,
    55: 2.0,
    52: 5.0,
    50: 6.5,
    48: 8.0,
}


async def seed_stations():
    async with get_session() as session:
        existing = await session.execute(select(WeatherStationOrm.id))
        if existing.first():
            return
        for s in STATIONS:
            session.add(
                WeatherStationOrm(
                    name=s["name"],
                    city=s["city"],
                    latitude=s["lat"],
                    longitude=s["lon"],
                    elevation_m=s["elev"],
                )
            )
        await session.commit()


def _condition(prec_mm: float, wind_ms: float, humidity: float) -> str:
    if prec_mm > 5:
        return "rain"
    if humidity > 85 and prec_mm > 0.5:
        return "drizzle"
    if wind_ms > 15:
        return "windy"
    return "clear"


async def wait_for_migrations(poll_interval: float = 2.0) -> None:
    while True:
        try:
            async with get_session() as session:
                await session.execute(select(WeatherStationOrm).limit(1))
                await session.execute(select(WeatherMeasurementOrm).limit(1))
            print("DB schema detected. Starting generator...")
            return
        except Exception:
            print("Waiting for DB migrations to be applied...")
            await asyncio.sleep(poll_interval)
            continue


async def get_stations():
    async with get_session() as session:
        stations = list(
            (await session.execute(select(WeatherStationOrm))).scalars()
        )
        if not stations:
            await seed_stations()
            stations = list(
                (await session.execute(select(WeatherStationOrm))).scalars()
            )

    return stations


async def generate_measurements(
    stations: List[WeatherStationOrm],
    t: float,
):
    async with get_session() as session:
        now = datetime.now(timezone.utc)
        rows = []
        for st in stations:
            nearest_lat_key = min(
                base_temp_by_lat.keys(), key=lambda k: abs(k - st.latitude)
            )
            base_temp = base_temp_by_lat[nearest_lat_key]

            diurnal = 5.0 * math.sin(
                (t % (24 * 3600)) / (24 * 3600) * 2 * math.pi
            )
            temp = base_temp + diurnal + random.uniform(-2.5, 2.5)

            humidity = max(
                20.0, min(100.0, 70.0 + random.uniform(-20.0, 20.0))
            )
            pressure = 1013.0 + random.uniform(-15.0, 15.0)
            wind_speed = max(0.0, random.gauss(5.0, 2.0))
            wind_dir = int(random.uniform(0, 360))
            precipitation = (
                max(0.0, random.gauss(0.3, 0.5)) if humidity > 75 else 0.0
            )
            cond = _condition(precipitation, wind_speed, humidity)

            rows.append(
                WeatherMeasurementOrm(
                    station_id=st.id,
                    measured_at=now,
                    temperature_c=temp,
                    humidity_pct=humidity,
                    pressure_hpa=pressure,
                    wind_speed_ms=wind_speed,
                    wind_dir_deg=wind_dir,
                    precipitation_mm=precipitation,
                    condition=cond,
                )
            )

        session.add_all(rows)
        try:
            await session.commit()
        except Exception:
            await session.rollback()

        print(f"added {len(rows)} rows")


async def main():
    await wait_for_migrations()

    stations = await get_stations()
    t = 0.0

    while True:
        await generate_measurements(
            stations=stations,
            t=t,
        )

        t += 1
        await asyncio.sleep(1)


if __name__ == "__main__":
    asyncio.run(main())
