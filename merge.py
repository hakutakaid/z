import json

# Nama file input
input_file = "data.json"
output_file = "merged.json"

# Variabel untuk menyimpan hasil gabungan
merged = {"name": None, "points": []}

# Baca tiap baris JSON dan gabungkan
with open(input_file, "r") as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        data = json.loads(line)
        if merged["name"] is None:
            merged["name"] = data["name"]
        merged["points"].extend(data.get("points", []))

# Simpan hasilnya ke file baru
with open(output_file, "w") as f:
    json.dump(merged, f, indent=2)

print("✅ Semua data berhasil digabung ke", output_file)