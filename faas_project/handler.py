import json
from datetime import datetime


def handler(event, context):
    """Fonction Lambda : traite un evenement et retourne une reponse"""
    print(f"[Lambda] Evenement recu : {json.dumps(event)}")

    nom = event.get("nom", "Inconnu")
    action = event.get("action", "saluer")

    if action == "saluer":
        message = f"Bonjour {nom} ! Il est {datetime.now().strftime('%H:%M')}"
    elif action == "calculer":
        nb = event.get("nombre", 0)
        message = f"Le carre de {nb} est {nb ** 2}"
    else:
        message = f"Action inconnue : {action}"

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": message,
            "timestamp": datetime.now().isoformat()
        })
    }
