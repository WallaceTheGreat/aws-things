import boto3, time, os, tempfile

CONFIG = dict(
    endpoint_url="http://localhost:4566",
    region_name="us-east-1",
    aws_access_key_id="test",
    aws_secret_access_key="test",
)
s3 = boto3.client("s3", **CONFIG)
BUCKET = "benchmark-object-storage"
TAILLES = [1 * 1024, 100 * 1024, 10 * 1024 * 1024]  # 1Ko, 100Ko, 10Mo


def bench_object_storage():
    print("\n=== OBJECT STORAGE (S3) ===")
    for taille in TAILLES:
        data = os.urandom(taille)
        cle = f"test-{taille}.bin"

        debut = time.perf_counter()
        s3.put_object(Bucket=BUCKET, Key=cle, Body=data)
        t_ecriture = (time.perf_counter() - debut) * 1000

        debut = time.perf_counter()
        s3.get_object(Bucket=BUCKET, Key=cle)
        t_lecture = (time.perf_counter() - debut) * 1000

        print(f"  {taille // 1024:>6} Ko | Ecriture: {t_ecriture:7.2f}ms | Lecture: {t_lecture:7.2f}ms")


def bench_block_storage():
    """Simule un block storage avec fichiers locaux (equivalent EBS)"""
    print("\n=== BLOCK STORAGE (EBS simule - fichier local) ===")
    with tempfile.TemporaryDirectory() as tmpdir:
        for taille in TAILLES:
            data = os.urandom(taille)
            chemin = os.path.join(tmpdir, f"test-{taille}.bin")

            debut = time.perf_counter()
            with open(chemin, "wb") as f:
                f.write(data)
            t_ecriture = (time.perf_counter() - debut) * 1000

            debut = time.perf_counter()
            with open(chemin, "rb") as f:
                f.read()
            t_lecture = (time.perf_counter() - debut) * 1000

            print(f"  {taille // 1024:>6} Ko | Ecriture: {t_ecriture:7.2f}ms | Lecture: {t_lecture:7.2f}ms")


def calculer_couts_1to():
    print("\n=== COUT MENSUEL POUR 1 To ===")
    print(f"  S3 Standard   : ~23 EUR/mois (0.023 USD/Go)")
    print(f"  S3 + requetes : ~25 EUR/mois (+ 0.004 USD/1000 requetes GET)")
    print(f"  EBS gp3       : ~82 EUR/mois (0.08 USD/Go)")
    print(f"  EBS io2       : ~125 EUR/mois (0.125 USD/Go)")
    print(f"  => Economie S3 vs EBS gp3 : ~57 EUR/mois pour 1 To")


if __name__ == "__main__":
    bench_object_storage()
    bench_block_storage()
    calculer_couts_1to()
