import os

files = [
    r"lib/main.dart",
    r"lib/screens/profile/settings_screen.dart",
    r"lib/screens/profile/privacy_policy_screen.dart",
    r"lib/screens/profile/language_screen.dart",
    r"lib/screens/profile/help_center_screen.dart",
    r"lib/screens/onboarding/onboarding_screen.dart",
    r"lib/screens/onboarding/splash_screen.dart",
    r"lib/screens/dashboard/dashboard_screen.dart",
    r"lib/screens/auth/document_verification_screen.dart",
    r"lib/screens/auth/forgot_password_screen.dart",
    r"lib/screens/auth/otp_verification_screen.dart",
    r"lib/screens/auth/profile_setup_screen.dart",
    r"lib/screens/auth/update_password_screen.dart",
    r"lib/screens/auth/vehicle_info_screen.dart",
    r"lib/screens/auth/sign_up_screen.dart",
    r"lib/screens/auth/login_screen.dart"
]

target_dir = r"c:\Users\Khuzaima\Downloads\driver_fuel-main\driver_fuel-main"

for f in files:
    full_path = os.path.join(target_dir, f.replace('/', os.sep))
    if os.path.exists(full_path):
        print(f"Modifying {f}...")
        with open(full_path, 'r', encoding='utf-8') as file:
            content = file.read()
        
        new_content = content.replace(
            "package:flutter_gen/gen_l10n/app_localizations.dart",
            "package:fueldirect_app/l10n/app_localizations.dart"
        )
        
        with open(full_path, 'w', encoding='utf-8') as file:
            file.write(new_content)
    else:
        print(f"File {f} not found!")

print("All imports replaced successfully.")
