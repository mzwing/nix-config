{
  mzwing.features."darwin/system" = {
    meta.platforms = ["darwin"];

    darwin = {
      security.pam.services.sudo_local.touchIdAuth = true;
      time.timeZone = "Asia/Singapore";

      system = {
        stateVersion = 6;

        defaults = {
          menuExtraClock.Show24Hour = true;

          dock = {
            autohide = false;
          };

          finder = {
            _FXShowPosixPathInTitle = false;
            AppleShowAllExtensions = true;
            FXEnableExtensionChangeWarning = false;
            QuitMenuItem = true;
            ShowPathbar = true;
            ShowStatusBar = true;
          };

          trackpad = {
            Clicking = true;
            TrackpadRightClick = true;
            TrackpadThreeFingerDrag = true;
          };

          NSGlobalDomain = {
            "com.apple.swipescrolldirection" = false;
            "com.apple.sound.beep.feedback" = 0;
            AppleInterfaceStyle = "Dark";
            AppleKeyboardUIMode = 0;
            ApplePressAndHoldEnabled = true;
            NSAutomaticCapitalizationEnabled = false;
            NSAutomaticDashSubstitutionEnabled = true;
            NSAutomaticPeriodSubstitutionEnabled = true;
            NSAutomaticQuoteSubstitutionEnabled = true;
            NSAutomaticSpellingCorrectionEnabled = true;
            NSNavPanelExpandedStateForSaveMode = true;
            NSNavPanelExpandedStateForSaveMode2 = true;
          };

          CustomUserPreferences = {
            ".GlobalPreferences".AppleSpacesSwitchOnActivate = true;
            NSGlobalDomain.WebKitDeveloperExtras = true;
            "com.apple.finder" = {
              ShowExternalHardDrivesOnDesktop = true;
              ShowHardDrivesOnDesktop = false;
              ShowMountedServersOnDesktop = true;
              ShowRemovableMediaOnDesktop = true;
              _FXSortFoldersFirst = true;
              FXDefaultSearchScope = "SCcf";
            };
            "com.apple.desktopservices" = {
              DSDontWriteNetworkStores = true;
              DSDontWriteUSBStores = true;
            };
            "com.apple.screensaver" = {
              askForPassword = 1;
              askForPasswordDelay = 0;
            };
            "com.apple.screencapture" = {
              location = "~/Desktop";
              type = "heic";
            };
            "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
            "com.apple.ImageCapture".disableHotPlug = true;
          };

          loginwindow = {
            GuestEnabled = false;
            SHOWFULLNAME = false;
          };
        };

        keyboard = {
          enableKeyMapping = true;
          remapCapsLockToControl = false;
          remapCapsLockToEscape = true;
          swapLeftCommandAndLeftAlt = false;
        };
      };

      environment.variables = {
        ANDROID_HOME = "/opt/homebrew/share/android-commandlinetools";
        ANDROID_SDK_ROOT = "/opt/homebrew/share/android-commandlinetools";
      };
    };
  };
}
