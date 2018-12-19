include $(THEOS)/makefiles/common.mk

TWEAK_NAME = DontKillMyMusic
DontKillMyMusic_FILES = Tweak.xm
DontKillMyMusic_LIBRARIES = sparkapplist
include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += dontkillmymusic
include $(THEOS_MAKE_PATH)/aggregate.mk
