TARGET := iphone:clang:latest:15.0

THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = 26BarPrefs

26BarPrefs_FILES = $(wildcard *.m)
26BarPrefs_FRAMEWORKS = UIKit
26BarPrefs_INSTALL_PATH = /Library/PreferenceBundles
26BarPrefs_CFLAGS = -fobjc-arc
26BarPrefs_LDFLAGS = -undefined dynamic_lookup

include $(THEOS_MAKE_PATH)/bundle.mk
