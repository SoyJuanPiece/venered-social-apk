-- ========================================================
-- DEBUG FINAL: VER EL ERROR REAL DE ONESIGNAL (CORREGIDO)
-- ========================================================

-- Esta consulta nos dirá exactamente qué respondió OneSignal
-- Si ves un código 400 o 401, ahí está el problema.
SELECT 
    status_code, 
    content, 
    created 
FROM net._http_response 
ORDER BY created DESC 
LIMIT 10;
