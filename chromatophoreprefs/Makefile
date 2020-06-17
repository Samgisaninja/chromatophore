include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = chromatophoreprefs

chromatophoreprefs_FILES = chromatophoreprefsRootListController.m
chromatophoreprefs_INSTALL_PATH = /Library/PreferenceBundles
chromatophoreprefs_FRAMEWORKS = UIKit
chromatophoreprefs_PRIVATE_FRAMEWORKS = Preferences
chromatophoreprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/chromatophoreprefs.plist$(ECHO_END)
