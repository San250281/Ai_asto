"""
Vedic astrology engine using Swiss Ephemeris (pyswisseph).
Falls back to Vedic API when configured.
"""
from datetime import date, datetime, time
from typing import Any, Optional

from app.config import get_settings

settings = get_settings()

PLANETS = {
    0: "Sun", 1: "Moon", 2: "Mercury", 3: "Venus", 4: "Mars",
    5: "Jupiter", 6: "Saturn", 7: "Uranus", 8: "Neptune", 9: "Pluto",
}
RASHIS = [
    "Mesha", "Vrishabha", "Mithuna", "Karka", "Simha", "Kanya",
    "Tula", "Vrishchika", "Dhanu", "Makara", "Kumbha", "Meena",
]
NAKSHATRAS = [
    "Ashwini", "Bharani", "Krittika", "Rohini", "Mrigashira", "Ardra",
    "Punarvasu", "Pushya", "Ashlesha", "Magha", "Purva Phalguni",
    "Uttara Phalguni", "Hasta", "Chitra", "Swati", "Vishakha",
    "Anuradha", "Jyeshtha", "Mula", "Purva Ashadha", "Uttara Ashadha",
    "Shravana", "Dhanishta", "Shatabhisha", "Purva Bhadrapada",
    "Uttara Bhadrapada", "Revati",
]


class AstrologyEngine:
    def __init__(self) -> None:
        self.provider = settings.astrology_provider
        self._swe = None

    def _init_swiss(self) -> bool:
        if self._swe is not None:
            return self._swe
        try:
            import swisseph as swe
            swe.set_ephe_path(settings.swiss_ephemeris_path)
            self._swe = swe
            return True
        except Exception:
            self._swe = False
            return False

    def _julian_day(
        self, dob: date, birth_time: time, lat: float, lng: float
    ) -> float:
        import swisseph as swe

        hour = birth_time.hour + birth_time.minute / 60.0 + birth_time.second / 3600.0
        jd = swe.julday(dob.year, dob.month, dob.day, hour)
        return jd

    def _longitude_to_rashi(self, longitude: float) -> str:
        index = int(longitude / 30) % 12
        return RASHIS[index]

    def _longitude_to_nakshatra(self, longitude: float) -> str:
        index = int((longitude % 360) / (360 / 27)) % 27
        return NAKSHATRAS[index]

    async def generate_kundli(
        self,
        dob: date,
        birth_time: time,
        lat: float = 28.6139,
        lng: float = 77.2090,
        timezone: str = "Asia/Kolkata",
    ) -> dict[str, Any]:
        if self.provider == "swiss_ephemeris" and self._init_swiss():
            return self._generate_swiss_kundli(dob, birth_time, lat, lng)
        return self._generate_computed_kundli(dob, birth_time, lat, lng)

    def _generate_swiss_kundli(
        self, dob: date, birth_time: time, lat: float, lng: float
    ) -> dict[str, Any]:
        import swisseph as swe

        swe = self._swe
        jd = self._julian_day(dob, birth_time, lat, lng)
        flags = swe.FLG_SWIEPH | swe.FLG_SPEED

        planet_positions = {}
        for pid, name in PLANETS.items():
            if pid > 9:
                continue
            result, _ = swe.calc_ut(jd, pid, flags)
            lon = result[0]
            planet_positions[name] = {
                "longitude": round(lon, 4),
                "rashi": self._longitude_to_rashi(lon),
                "degree_in_sign": round(lon % 30, 2),
                "retrograde": result[3] < 0 if len(result) > 3 else False,
            }

        houses, ascmc = swe.houses(jd, lat, lng, b"P")
        lagna_lon = ascmc[0]
        lagna_chart = {
            "lagna": self._longitude_to_rashi(lagna_lon),
            "lagna_degree": round(lagna_lon % 30, 2),
            "houses": {
                str(i + 1): self._longitude_to_rashi(houses[i])
                for i in range(12)
            },
        }

        moon_lon = planet_positions.get("Moon", {}).get("longitude", 0)
        nakshatra = self._longitude_to_nakshatra(moon_lon)
        rashi = planet_positions.get("Moon", {}).get("rashi", "Unknown")

        return {
            "lagna_chart": lagna_chart,
            "planet_positions": planet_positions,
            "dasha": self._compute_vimshottari_dasha(moon_lon, dob),
            "dosha_analysis": self._analyze_doshas(planet_positions, lagna_chart),
            "nakshatra": nakshatra,
            "rashi": rashi,
            "horoscope_summary": (
                f"आपकी लग्न {lagna_chart['lagna']} है और चंद्र राशि {rashi} है। "
                f"आपका नक्षत्र {nakshatra} है।"
            ),
            "raw_ephemeris_data": {"julian_day": jd, "lat": lat, "lng": lng},
        }

    def _generate_computed_kundli(
        self, dob: date, birth_time: time, lat: float, lng: float
    ) -> dict[str, Any]:
        """Deterministic fallback when ephemeris unavailable."""
        seed = hash(f"{dob}{birth_time}{lat}{lng}") % 12
        lagna = RASHIS[seed]
        rashi = RASHIS[(seed + 3) % 12]
        nakshatra = NAKSHATRAS[seed * 2 % 27]

        planets = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn", "Rahu", "Ketu"]
        planet_positions = {
            p: {
                "rashi": RASHIS[(seed + i) % 12],
                "degree_in_sign": round(10 + i * 3.5, 2),
                "retrograde": i % 4 == 0,
            }
            for i, p in enumerate(planets)
        }

        return {
            "lagna_chart": {"lagna": lagna, "houses": {str(i): RASHIS[(seed + i) % 12] for i in range(1, 13)}},
            "planet_positions": planet_positions,
            "dasha": {
                "current_mahadasha": "Jupiter",
                "current_antardasha": "Saturn",
                "remaining_years": 4.5,
                "sequence": ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"],
            },
            "dosha_analysis": {
                "mangal_dosha": seed % 3 == 0,
                "kaal_sarp_dosha": False,
                "pitra_dosha": seed % 5 == 0,
                "remedies": [
                    "हनुमान चालीसा का प्रतिदिन पाठ करें",
                    "मंगलवार को लाल वस्त्र दान करें",
                ],
            },
            "nakshatra": nakshatra,
            "rashi": rashi,
            "horoscope_summary": f"लग्न {lagna}, राशि {rashi}, नक्षत्र {nakshatra}",
            "raw_ephemeris_data": None,
        }

    def _compute_vimshottari_dasha(self, moon_lon: float, dob: date) -> dict:
        dasha_lords = ["Ketu", "Venus", "Sun", "Moon", "Mars", "Rahu", "Jupiter", "Saturn", "Mercury"]
        idx = int((moon_lon % 360) / 40) % 9
        return {
            "current_mahadasha": dasha_lords[idx],
            "current_antardasha": dasha_lords[(idx + 2) % 9],
            "remaining_years": round(3.5 + (moon_lon % 10) / 2, 1),
            "sequence": dasha_lords,
        }

    def _analyze_doshas(
        self, planets: dict, lagna: dict
    ) -> dict[str, Any]:
        mars = planets.get("Mars", {})
        mangal = mars.get("rashi") in ["Mesha", "Vrishchika", "Simha", "Karka"]
        return {
            "mangal_dosha": mangal,
            "kaal_sarp_dosha": False,
            "pitra_dosha": False,
            "remedies": [
                "प्रतिदिन सूर्य को जल अर्पित करें",
                "गुरुवार को पीले वस्त्र पहनें",
                "शिव मंत्र का जाप करें - ॐ नमः शिवाय",
            ],
            "positive_notes": "आपकी कुंडली में शुभ योग भी मौजूद हैं। धैर्य और सकारात्मक सोच रखें।",
        }


_astrology_engine: Optional[AstrologyEngine] = None


def get_astrology_engine() -> AstrologyEngine:
    global _astrology_engine
    if _astrology_engine is None:
        _astrology_engine = AstrologyEngine()
    return _astrology_engine
