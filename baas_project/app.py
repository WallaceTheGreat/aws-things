import boto3
import uuid
import json
from datetime import datetime, timedelta

config = dict(
    endpoint_url="http://localhost:4566",
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test"
)

dynamo = boto3.resource("dynamodb", **config)
s3     = boto3.client("s3", **config)


def creer_utilisateur(nom, email):
    table = dynamo.Table("baas-users")
    user = {
        "userId": str(uuid.uuid4()),
        "nom": nom,
        "email": email,
        "creeA": datetime.now().isoformat()
    }
    table.put_item(Item=user)
    print(f"[BaaS] Utilisateur cree : {nom} ({user['userId'][:8]}...)")
    return user


def creer_session(user_id):
    table = dynamo.Table("baas-sessions")
    session = {
        "sessionId": str(uuid.uuid4()),
        "userId": user_id,
        "creeA": datetime.now().isoformat(),
        "expiresAt": int((datetime.now() + timedelta(hours=24)).timestamp())
    }
    table.put_item(Item=session)
    print(f"[BaaS] Session creee pour userId={user_id[:8]}...")
    return session


def uploader_fichier(user_id, nom_fichier, contenu):
    cle = f"users/{user_id}/{nom_fichier}"
    s3.put_object(Bucket="baas-user-files", Key=cle, Body=contenu.encode())
    print(f"[BaaS] Fichier uploade : {cle}")


def lister_utilisateurs():
    table = dynamo.Table("baas-users")
    response = table.scan()
    users = response.get("Items", [])
    print(f"[BaaS] {len(users)} utilisateur(s) en base :")
    for u in users:
        print(f"  - {u['nom']} <{u['email']}> ({u['userId'][:8]}...)")
    return users


if __name__ == "__main__":
    u = creer_utilisateur("Alice Dupont", "alice@exemple.fr")
    creer_session(u["userId"])
    uploader_fichier(u["userId"], "profil.txt", "Donnees profil Alice")

    u2 = creer_utilisateur("Bob Martin", "bob@exemple.fr")
    uploader_fichier(u2["userId"], "avatar.txt", "Donnees avatar Bob")

    print()
    lister_utilisateurs()
    print("[BaaS] Application BaaS operationnelle !")
