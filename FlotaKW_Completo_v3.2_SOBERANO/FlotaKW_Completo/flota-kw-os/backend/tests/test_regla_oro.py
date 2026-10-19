from app.services.alta_service import aplicar_regla_de_oro
from fastapi import HTTPException

def test_sin_r_retorna_calamp():
    gps, tipo = aplicar_regla_de_oro("KW-1234", None)
    assert gps == "CALAMP" and tipo == "CALAMP"

def test_sin_r_ignora_input():
    gps, tipo = aplicar_regla_de_oro("KW-1234", "QUECLINK GV300")
    assert gps == "CALAMP"

def test_con_r_requiere_gps():
    try:
        aplicar_regla_de_oro("KW-1234_R", None)
        assert False
    except HTTPException as e:
        assert e.status_code == 400

def test_con_r_retorna_variable():
    gps, tipo = aplicar_regla_de_oro("KW-1234_R", "Teltonika FMB920")
    assert tipo == "VARIABLE"
    assert "TELTONIKA" in gps
