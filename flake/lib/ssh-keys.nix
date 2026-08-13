# Shared pool of device SSH public keys.
#
# Single source of truth feeding BOTH sides of the "all devices reach all
# devices" setup:
#   - modules/users/aliyss.nix  → NixOS sshd authorizedKeys
#   - hosts/termux/home.nix     → the phone's real ~/.ssh/authorized_keys
# So ssh-blisspla / ssh-bequitta / ssh-blade / ssh-termux all round-trip.
[
  # blisspla (this desktop)
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIG8EXYkBwLD1WbJoI2CS2dK3Z9wvlr/NmZip97IqWlK silyas.bieri@lagomio.com"
  # bequitta / legacy desktop keys
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFg3asHQc8AL+AxLg1Cnp2s18KMqybp/AUBmT5vP0NUY"
  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyLEiHivwO4cvA0pv2SX1QkE88AjK4BUADOxjuZaRQxXVT3RSioxUAy6/WRQnlg+Z1uG6+ltgszpm2uf1/dFrXKkY1Gvx/LZKn9fcSyqwVEs9/RHaj2+RwIzdTqEJ8lcqZmrRZv2u9iFmU19vWU9io3VUszqHTbPk7Bq1F0HKPRPMyC+3rWa6H84tfQdvpXw84kFWMJ/+hpDLwC7Q2LRwAr32QAtICO9gqJjvY2fGYrlHECvhct3fphpWPss6DUwklIBgGlH7LraqFuL8S/88tLGH2hbEtTav86XWch2piOhH20CBtKvJgWBrg/ahqI27RWRbm9+miTr3D9tXceX4hHou2QLjIgykf59r1crGrc24Q6apfEBUzl0pBtiEMkP3DN8aHO2F333Ky1y7nxBHwXLt/6xPO+RUKuclzloaq+NIrTsM8Y7GxCBZhsFusSTywsTjkufcSjhY2O8eBjpOlTroqKp17URpkpjwC/gev+ewFgt1UMnwcgiSttJDK7gM= aliyss@aliyss-bequitta"
  # termux (phone)
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAVGyd/USfVnQEzaEeV+36VpWrBweVl/2a6bmKD6gVpq aliyss-termux"
]