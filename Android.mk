LOCAL_PATH := $(call my-dir)
BB_PATH := $(LOCAL_PATH)


LOCAL_PATH := $(BB_PATH)
include $(CLEAR_VARS)

BB_VER := 1.25.0-bionic

# On aosp (master), path is relative, not on cm (kitkat)
bb_gen := $(abspath $(TARGET_OUT_INTERMEDIATES)/busybox)

KERNEL_MODULES_DIR ?= /system/lib/modules

BUSYBOX_SRC_FILES = $(shell cat $(BB_PATH)/android/android.sources)

BUSYBOX_C_INCLUDES = \
	$(BB_PATH)/include $(BB_PATH)/libbb \
	$(BB_PATH)/android/include \
	bionic/libc/private \
	bionic/libc \
	bionic/libm/include \
	bionic/libc/include \
	bionic/libm/include \
	external/libselinux/include \
	external/selinux/libsepol/include \

BUSYBOX_CFLAGS = \
	-Werror=implicit -Wno-clobbered \
	-DNDEBUG \
	-DANDROID \
	-D__USE_GNU \
	-fno-strict-aliasing \
	-fno-builtin-stpcpy \
	-include $(BB_PATH)/android/include/autoconf.h \
	-D'CONFIG_DEFAULT_MODULES_DIR="$(KERNEL_MODULES_DIR)"' \
	-D'BB_VER="$(BB_VER)"' -DBB_BT=AUTOCONF_TIMESTAMP

# Bionic Busybox /system/xbin

LOCAL_SRC_FILES := $(BUSYBOX_SRC_FILES)
LOCAL_C_INCLUDES := $(BUSYBOX_C_INCLUDES)
LOCAL_CFLAGS := $(BUSYBOX_CFLAGS)
LOCAL_ASFLAGS := $(BUSYBOX_AFLAGS)
LOCAL_MODULE := busybox
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT_OPTIONAL_EXECUTABLES)
LOCAL_SHARED_LIBRARIES := libc libcutils libm libselinux
LOCAL_STATIC_LIBRARIES := libsepol
LOCAL_CLANG := false
include $(BUILD_EXECUTABLE)

BUSYBOX_LINKS := $(shell cat $(BB_PATH)/android/android.links)
# nc is provided by external/netcat
exclude := nc
SYMLINKS := $(addprefix $(TARGET_OUT_OPTIONAL_EXECUTABLES)/,$(filter-out $(exclude),$(notdir $(BUSYBOX_LINKS))))
$(SYMLINKS): BUSYBOX_BINARY := $(LOCAL_MODULE)
$(SYMLINKS): $(LOCAL_INSTALLED_MODULE)
	@echo -e ${CL_CYN}"Symlink:"${CL_RST}" $@ -> $(BUSYBOX_BINARY)"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf $(BUSYBOX_BINARY) $@

ALL_DEFAULT_INSTALLED_MODULES += $(SYMLINKS)

# We need this so that the installed files could be picked up based on the
# local module name
ALL_MODULES.$(LOCAL_MODULE).INSTALLED := \
    $(ALL_MODULES.$(LOCAL_MODULE).INSTALLED) $(SYMLINKS)
